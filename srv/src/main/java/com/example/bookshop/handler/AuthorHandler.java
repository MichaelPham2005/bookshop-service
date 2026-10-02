package com.example.bookshop.handler;

import cds.gen.bookshop.management.Books;
import cds.gen.bookshop.management.Books_;
import cds.gen.catalogservice.Authors;
import cds.gen.catalogservice.CatalogService_;
import cds.gen.sap.common.Countries;
import cds.gen.sap.common.Countries_;
import com.sap.cds.ql.Select;
import com.sap.cds.ql.cqn.CqnAnalyzer;
import com.sap.cds.services.cds.CdsCreateEventContext;
import com.sap.cds.services.cds.CdsDeleteEventContext;
import com.sap.cds.services.cds.CqnService;
import com.sap.cds.services.draft.DraftSaveEventContext;
import com.sap.cds.services.draft.DraftService;
import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.After;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.ServiceName;
import com.sap.cds.services.messages.Messages;
import com.sap.cds.services.persistence.PersistenceService;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

@Component
@ServiceName(CatalogService_.CDS_NAME)
public class AuthorHandler implements EventHandler {

  private final PersistenceService persistenceService;

  public AuthorHandler(PersistenceService persistenceService) {
    this.persistenceService = persistenceService;
  }

  @After(event = CqnService.EVENT_READ, entity = cds.gen.catalogservice.Authors_.CDS_NAME)
  public void addBookCounts(List<Authors> authors) {
    Map<String, Long> counts =
        persistenceService
            .run(Select.from(Books_.class).columns(b -> b.author_ID()))
            .listOf(Books.class)
            .stream()
            .filter(book -> book.getAuthorId() != null)
            .collect(Collectors.groupingBy(Books::getAuthorId, Collectors.counting()));
    Map<String, String> countryNames =
        persistenceService
            .run(Select.from(Countries_.class).columns(c -> c.code(), c -> c.name()))
            .listOf(Countries.class)
            .stream()
            .collect(Collectors.toMap(Countries::getCode, Countries::getName));
    Map<String, String> authorCountries =
        persistenceService
            .run(
                Select.from(cds.gen.bookshop.management.Authors_.class)
                    .columns(author -> author.ID(), author -> author.countryCode()))
            .listOf(cds.gen.bookshop.management.Authors.class)
            .stream()
            .filter(author -> author.getCountryCode() != null)
            .collect(
                Collectors.toMap(
                    cds.gen.bookshop.management.Authors::getId,
                    cds.gen.bookshop.management.Authors::getCountryCode));

    authors.forEach(
        author -> {
          author.setBookCount(Math.toIntExact(counts.getOrDefault(author.getId(), 0L)));
          String countryCode =
              author.getCountryCode() != null
                  ? author.getCountryCode()
                  : authorCountries.get(author.getId());
          author.setCountryName(countryNames.getOrDefault(countryCode, countryCode));
        });
  }

  @Before(
      event = {DraftService.EVENT_DRAFT_NEW, CqnService.EVENT_CREATE},
      entity = cds.gen.catalogservice.Authors_.CDS_NAME)
  public void applyCreateDefaults(Authors author) {
    if (author.getId() == null) {
      author.setId(UUID.randomUUID().toString());
    }
    if (author.getAuthorId() == null || author.getAuthorId().isBlank()) {
      author.setAuthorId(createAuthorId(author.getId()));
    }
    if (author.getBiography() == null) {
      author.setBiography("");
    }
  }

  @Before(event = DraftService.EVENT_DRAFT_SAVE, entity = cds.gen.catalogservice.Authors_.CDS_NAME)
  public void validateDraft(DraftSaveEventContext context) {
    Authors author = context.getService().run(context.getCqn()).single(Authors.class);
    validate(author, context.getMessages());
  }

  @Before(event = CqnService.EVENT_CREATE, entity = cds.gen.catalogservice.Authors_.CDS_NAME)
  public void validateActiveCreate(Authors author, CdsCreateEventContext context) {
    validate(author, context.getMessages());
  }

  @Before(event = CqnService.EVENT_DELETE, entity = cds.gen.catalogservice.Authors_.CDS_NAME)
  public void validateDelete(CdsDeleteEventContext context) {
    Object authorId =
        CqnAnalyzer.create(context.getModel())
            .analyze(context.getCqn())
            .targetKeys()
            .get(Authors.ID);
    if (authorId == null) {
      context.getMessages().error("Select an author to delete.");
      context.getMessages().throwIfError();
      return;
    }

    String id = authorId.toString();
    boolean hasActiveBooks =
        persistenceService
            .run(Select.from(Books_.class).columns(b -> b.ID()).where(b -> b.author_ID().eq(id)).limit(1))
            .first()
            .isPresent();
    boolean hasDraftBooks =
        context
            .getService()
            .run(
                Select.from(cds.gen.catalogservice.Books_.class)
                    .columns(b -> b.ID())
                    .where(b -> b.author_ID().eq(id).and(b.IsActiveEntity().eq(false)))
                    .limit(1))
            .first()
            .isPresent();

    if (hasActiveBooks || hasDraftBooks) {
      context
          .getMessages()
          .error("Delete all books by this author before deleting the author.");
      context.getMessages().throwIfError();
    }
  }

  private void validate(Authors author, Messages messages) {
    String displayName = author.getDisplayName() == null ? "" : author.getDisplayName().trim();
    String countryCode =
        author.getCountryCode() == null
            ? ""
            : author.getCountryCode().trim().toUpperCase(Locale.ROOT);
    author.setDisplayName(displayName);
    author.setCountryCode(countryCode);
    if (author.getBiography() == null) {
      author.setBiography("");
    } else {
      author.setBiography(author.getBiography().trim());
    }

    if (displayName.isEmpty() || displayName.length() > 120) {
      messages.error("Enter an author name with no more than 120 characters.").target(Authors.DISPLAY_NAME);
    }
    if (!countryExists(countryCode)) {
      messages.error("Select a country from the list.").target(Authors.COUNTRY_CODE);
    }
    messages.throwIfError();
  }

  private boolean countryExists(String countryCode) {
    return !countryCode.isEmpty()
        && persistenceService
            .run(Select.from(Countries_.class).columns(c -> c.code()).where(c -> c.code().eq(countryCode)).limit(1))
            .first()
            .isPresent();
  }

  private String createAuthorId(String id) {
    UUID uuid = UUID.fromString(id);
    String value = Long.toUnsignedString(uuid.getMostSignificantBits(), 36).toUpperCase(Locale.ROOT);
    String suffix = value.length() >= 5 ? value.substring(0, 5) : "0".repeat(5 - value.length()) + value;
    return "A" + suffix;
  }
}

package com.example.bookshop.handler;

import cds.gen.bookshop.management.Books_;
import cds.gen.bookshop.management.Categories_;
import cds.gen.catalogservice.CatalogService_;
import cds.gen.catalogservice.Categories;
import com.sap.cds.ql.Select;
import com.sap.cds.ql.cqn.CqnAnalyzer;
import com.sap.cds.services.cds.CdsCreateEventContext;
import com.sap.cds.services.cds.CdsDeleteEventContext;
import com.sap.cds.services.cds.CqnService;
import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.ServiceName;
import com.sap.cds.services.persistence.PersistenceService;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
@ServiceName(CatalogService_.CDS_NAME)
public class CategoryHandler implements EventHandler {

  private static final int SORT_ORDER_STEP = 10;

  private final PersistenceService persistenceService;

  public CategoryHandler(PersistenceService persistenceService) {
    this.persistenceService = persistenceService;
  }

  @Before(event = CqnService.EVENT_CREATE, entity = cds.gen.catalogservice.Categories_.CDS_NAME)
  public void applySystemFields(Categories category, CdsCreateEventContext context) {
    String name = category.getName() == null ? "" : category.getName().trim();
    if (name.isEmpty()) {
      context.getMessages().error("Enter a category name.").target(Categories.NAME);
      context.getMessages().throwIfError();
    }

    UUID uuid = UUID.randomUUID();
    String id = uuid.toString();
    List<cds.gen.bookshop.management.Categories> existingCategories =
        persistenceService
            .run(
                Select.from(Categories_.class)
                    .columns(c -> c.ID(), c -> c.parent_ID(), c -> c.level(), c -> c.sortOrder()))
            .listOf(cds.gen.bookshop.management.Categories.class);

    cds.gen.bookshop.management.Categories parent =
        existingCategories.stream()
            .filter(existing -> Objects.equals(existing.getId(), category.getParentId()))
            .findFirst()
            .orElse(null);

    if (category.getParentId() != null && parent == null) {
      context.getMessages().error("Select an existing parent category.").target(Categories.PARENT_ID);
      context.getMessages().throwIfError();
    }

    int nextSortOrder =
        existingCategories.stream()
            .filter(existing -> Objects.equals(existing.getParentId(), category.getParentId()))
            .map(cds.gen.bookshop.management.Categories::getSortOrder)
            .filter(Objects::nonNull)
            .max(Integer::compareTo)
            .orElse(0)
            + SORT_ORDER_STEP;

    category.setId(id);
    category.setCategoryId(createCategoryId(uuid));
    category.setName(name);
    category.setLevel(parent == null ? 1 : parent.getLevel() + 1);
    category.setSortOrder(nextSortOrder);
  }

  @Before(event = CqnService.EVENT_DELETE, entity = cds.gen.catalogservice.Categories_.CDS_NAME)
  public void validateDelete(CdsDeleteEventContext context) {
    Object categoryId =
        CqnAnalyzer.create(context.getModel())
            .analyze(context.getCqn())
            .targetKeys()
            .get(Categories.ID);
    if (categoryId == null) {
      context.getMessages().error("Select a category to delete.");
      context.getMessages().throwIfError();
      return;
    }

    String id = categoryId.toString();
    boolean hasChildren =
        persistenceService
            .run(Select.from(Categories_.class).columns(c -> c.ID()).where(c -> c.parent_ID().eq(id)).limit(1))
            .first()
            .isPresent();
    boolean hasBooks =
        persistenceService
            .run(Select.from(Books_.class).columns(b -> b.ID()).where(b -> b.category_ID().eq(id)).limit(1))
            .first()
            .isPresent();

    if (hasBooks) {
      context.getMessages().error("Delete all books in this category before deleting it.");
      context.getMessages().throwIfError();
    }
    if (hasChildren) {
      context.getMessages().error("Delete all child categories before deleting this category.");
      context.getMessages().throwIfError();
    }
  }

  private String createCategoryId(UUID uuid) {
    String value = Long.toUnsignedString(uuid.getMostSignificantBits(), 36).toUpperCase();
    return value.length() >= 6 ? value.substring(0, 6) : "0".repeat(6 - value.length()) + value;
  }
}

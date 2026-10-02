package com.example.bookshop.handler;

import cds.gen.bookshop.management.Books_;
import cds.gen.bookshop.management.Inventory;
import cds.gen.bookshop.management.Inventory_;
import cds.gen.bookshop.management.Sales;
import cds.gen.bookshop.management.Sales_;
import cds.gen.bookshop.management.Suppliers;
import cds.gen.bookshop.management.Suppliers_;
import cds.gen.catalogservice.Books;
import cds.gen.catalogservice.CatalogService_;
import com.sap.cds.ql.Insert;
import com.sap.cds.ql.Select;
import com.sap.cds.services.cds.CqnService;
import com.sap.cds.services.cds.CdsCreateEventContext;
import com.sap.cds.services.draft.DraftSaveEventContext;
import com.sap.cds.services.draft.DraftService;
import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.After;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.ServiceName;
import com.sap.cds.services.messages.Messages;
import com.sap.cds.services.persistence.PersistenceService;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
@ServiceName(CatalogService_.CDS_NAME)
public class BookHandler implements EventHandler {

  private static final String DEFAULT_LANGUAGE = "English";
  private static final String DEFAULT_STORAGE_LOCATION = "NEW-BOOKS";
  private static final String DEFAULT_SUPPLIER_ID = "SUP001";
  private static final String DEFAULT_CURRENCY = "USD";

  private final PersistenceService persistenceService;

  public BookHandler(PersistenceService persistenceService) {
    this.persistenceService = persistenceService;
  }

  @After(event = CqnService.EVENT_READ, entity = cds.gen.catalogservice.Books_.CDS_NAME)
  public void addSalesSummaries(List<Books> books) {
    Map<String, Integer> unitsByBook = new HashMap<>();
    Map<String, BigDecimal> revenueByBook = new HashMap<>();

    persistenceService
        .run(Select.from(Sales_.class).columns(s -> s.book_ID(), s -> s.quantity(), s -> s.netAmount()))
        .listOf(Sales.class)
        .forEach(
            sale -> {
              if (sale.getBookId() == null) {
                return;
              }
              unitsByBook.merge(sale.getBookId(), sale.getQuantity(), Integer::sum);
              revenueByBook.merge(sale.getBookId(), sale.getNetAmount(), BigDecimal::add);
            });

    books.forEach(
        book -> {
          book.setUnitsSold(unitsByBook.getOrDefault(book.getId(), 0));
          book.setSalesRevenue(revenueByBook.getOrDefault(book.getId(), BigDecimal.ZERO));
        });
  }

  @Before(
      event = {DraftService.EVENT_DRAFT_NEW, CqnService.EVENT_CREATE},
      entity = cds.gen.catalogservice.Books_.CDS_NAME)
  public void applyCreateDefaults(Books book) {
    if (book.getId() == null) {
      book.setId(UUID.randomUUID().toString());
    }
    if (book.getBookId() == null || book.getBookId().isBlank()) {
      book.setBookId("B-" + book.getId().substring(0, 8).toUpperCase());
    }
    if (book.getDescription() == null) {
      book.setDescription("");
    }
    if (book.getLanguage() == null) {
      book.setLanguage(DEFAULT_LANGUAGE);
    }
    if (book.getPublicationDate() == null) {
      book.setPublicationDate(LocalDate.now());
    }
    if (book.getPageCount() == null) {
      book.setPageCount(1);
    }
    book.setCurrency(DEFAULT_CURRENCY);
    if (book.getRatingCount() == null) {
      book.setRatingCount(0);
    }
    if (book.getInitialStock() == null) {
      book.setInitialStock(0);
    }
    if (book.getReorderPoint() == null) {
      book.setReorderPoint(5);
    }
  }

  @Before(event = DraftService.EVENT_DRAFT_SAVE, entity = cds.gen.catalogservice.Books_.CDS_NAME)
  public void validateDraft(DraftSaveEventContext context) {
    Books book = context.getService().run(context.getCqn()).single(Books.class);
    validate(book, context.getMessages());
  }

  @Before(event = CqnService.EVENT_CREATE, entity = cds.gen.catalogservice.Books_.CDS_NAME)
  public void validateActiveCreate(Books book, CdsCreateEventContext context) {
    validate(book, context.getMessages());
  }

  @After(event = CqnService.EVENT_CREATE, entity = cds.gen.catalogservice.Books_.CDS_NAME)
  public void createInitialInventory(Books book) {
    if (book == null || book.getId() == null || inventoryExists(book.getId())) {
      return;
    }

    Suppliers supplier =
        persistenceService
            .run(
                Select.from(Suppliers_.class)
                    .columns(s -> s.ID())
                    .where(s -> s.supplierId().eq(DEFAULT_SUPPLIER_ID)))
            .single(Suppliers.class);

    int initialStock = book.getInitialStock();
    int reorderPoint = book.getReorderPoint();
    int targetStock = Math.max(reorderPoint * 2, 20);
    Inventory inventory = Inventory.create();
    inventory.setId(UUID.randomUUID().toString());
    inventory.setBookId(book.getId());
    inventory.setSupplierId(supplier.getId());
    inventory.setStorageLocation(DEFAULT_STORAGE_LOCATION);
    inventory.setOnHand(initialStock);
    inventory.setReserved(0);
    inventory.setReorderPoint(reorderPoint);
    inventory.setTargetStock(targetStock);
    inventory.setLastCountedAt(Instant.now());
    updateDerivedInventory(inventory, book.getPrice());
    persistenceService.run(Insert.into(Inventory_.class).entry(inventory));
  }

  private void validate(Books book, Messages messages) {
    String title = book.getTitle() == null ? "" : book.getTitle().trim();
    String isbn = book.getIsbn13() == null ? "" : book.getIsbn13().trim();
    book.setTitle(title);
    book.setIsbn13(isbn);

    if (title.isEmpty() || title.length() > 180) {
      messages.error("Enter a title with no more than 180 characters.").target(Books.TITLE);
    }
    if (!isbn.matches("\\d{13}")) {
      messages.error("Enter an ISBN with exactly 13 digits.").target(Books.ISBN13);
    } else if (isbnExists(isbn, book.getId())) {
      messages.error("A book with this ISBN already exists.").target(Books.ISBN13);
    }
    if (book.getAuthorId() == null) {
      messages.error("Select an author.").target(Books.AUTHOR_ID);
    }
    if (book.getCategoryId() == null) {
      messages.error("Select a category.").target(Books.CATEGORY_ID);
    }
    if (book.getPublisherId() == null) {
      messages.error("Select a publisher.").target(Books.PUBLISHER_ID);
    }
    if (book.getPrice() == null || book.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
      messages.error("Enter a price greater than zero.").target(Books.PRICE);
    }
    if (book.getInitialStock() == null || book.getInitialStock() < 0) {
      messages.error("Enter initial stock as a whole number of zero or greater.").target(Books.INITIAL_STOCK);
    }
    if (book.getReorderPoint() == null || book.getReorderPoint() < 0) {
      messages.error("Enter the reorder point as a whole number of zero or greater.").target(Books.REORDER_POINT);
    }
    messages.throwIfError();
  }

  private boolean isbnExists(String isbn, String currentId) {
    var result =
        persistenceService.run(
            Select.from(Books_.class)
                .columns(b -> b.ID())
                .where(
                    b ->
                        currentId == null
                            ? b.isbn13().eq(isbn)
                            : b.isbn13().eq(isbn).and(b.ID().ne(currentId)))
                .limit(1));
    return result.first().isPresent();
  }

  private boolean inventoryExists(String bookId) {
    return persistenceService
        .run(
            Select.from(Inventory_.class)
                .columns(i -> i.ID())
                .where(i -> i.book_ID().eq(bookId))
                .limit(1))
        .first()
        .isPresent();
  }

  public static void updateDerivedInventory(Inventory inventory, BigDecimal price) {
    int available = inventory.getOnHand() - inventory.getReserved();
    int targetStock = inventory.getTargetStock();
    int reorderPoint = inventory.getReorderPoint();
    String status;
    int criticality;
    if (available <= 0) {
      status = "Out of Stock";
      criticality = 1;
    } else if (available <= reorderPoint) {
      status = "Low Stock";
      criticality = 2;
    } else if (available > targetStock * 1.25) {
      status = "Overstock";
      criticality = 2;
    } else {
      status = "In Stock";
      criticality = 3;
    }
    inventory.setAvailable(available);
    inventory.setInventoryStatus(status);
    inventory.setInventoryStatusCriticality(criticality);
    inventory.setSuggestedRestockQuantity(Math.max(targetStock - available, 0));
    inventory.setInventoryValue(price.multiply(BigDecimal.valueOf(available)));
    inventory.setCurrency(DEFAULT_CURRENCY);
  }
}

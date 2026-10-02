package com.example.bookshop.handler;

import cds.gen.bookshop.management.Books;
import cds.gen.bookshop.management.Books_;
import cds.gen.bookshop.management.Inventory;
import cds.gen.bookshop.management.Inventory_;
import cds.gen.bookshop.management.RestockHistory;
import cds.gen.bookshop.management.RestockHistory_;
import cds.gen.bookshop.management.RestockRequests_;
import cds.gen.bookshop.management.StockMovements;
import cds.gen.bookshop.management.StockMovements_;
import cds.gen.bookshop.management.Suppliers;
import cds.gen.bookshop.management.Suppliers_;
import cds.gen.inventoryservice.InventoryService_;
import cds.gen.inventoryservice.RestockRequests;
import cds.gen.inventoryservice.RestockRequestsApproveContext;
import cds.gen.inventoryservice.RestockRequestsMarkOrderedContext;
import cds.gen.inventoryservice.RestockRequestsRecordReceiptContext;
import cds.gen.inventoryservice.RestockRequestsRejectContext;
import cds.gen.inventoryservice.RestockRequestsSubmitContext;
import com.sap.cds.CdsData;
import com.sap.cds.ql.Insert;
import com.sap.cds.ql.Select;
import com.sap.cds.ql.Update;
import com.sap.cds.ql.cqn.CqnAnalyzer;
import com.sap.cds.ql.cqn.CqnSelect;
import com.sap.cds.services.ErrorStatuses;
import com.sap.cds.services.EventContext;
import com.sap.cds.services.ServiceException;
import com.sap.cds.services.cds.CqnService;
import com.sap.cds.services.handler.EventHandler;
import com.sap.cds.services.handler.annotations.Before;
import com.sap.cds.services.handler.annotations.On;
import com.sap.cds.services.persistence.PersistenceService;
import com.sap.cds.services.draft.DraftService;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
public class RestockRequestHandler implements EventHandler {

  private static final List<String> OPEN_STATUSES =
      List.of("Draft", "Pending Review", "Approved", "Ordered", "Partially Received");

  private final PersistenceService persistenceService;

  public RestockRequestHandler(PersistenceService persistenceService) {
    this.persistenceService = persistenceService;
  }

  @Before(event = {DraftService.EVENT_DRAFT_NEW, CqnService.EVENT_CREATE}, entity = cds.gen.inventoryservice.RestockRequests_.CDS_NAME, service = InventoryService_.CDS_NAME)
  public void applyInventoryCreateDefaults(RestockRequests request) {
    applyCreateDefaults((CdsData) request);
  }

  @Before(event = {DraftService.EVENT_DRAFT_NEW, CqnService.EVENT_CREATE}, entity = cds.gen.catalogservice.RestockRequests_.CDS_NAME, service = cds.gen.catalogservice.CatalogService_.CDS_NAME)
  public void applyCatalogCreateDefaults(cds.gen.catalogservice.RestockRequests request) {
    applyCreateDefaults((CdsData) request);
  }

  @Before(
      event = {
        DraftService.EVENT_DRAFT_NEW,
        DraftService.EVENT_DRAFT_PATCH,
        CqnService.EVENT_CREATE,
        CqnService.EVENT_UPDATE
      },
      entity = cds.gen.inventoryservice.RestockRequests_.CDS_NAME,
      service = InventoryService_.CDS_NAME)
  public void deriveInventorySupplier(RestockRequests request) {
    deriveSupplierFromBook((CdsData) request);
  }

  @Before(
      event = {
        DraftService.EVENT_DRAFT_NEW,
        DraftService.EVENT_DRAFT_PATCH,
        CqnService.EVENT_CREATE,
        CqnService.EVENT_UPDATE
      },
      entity = cds.gen.catalogservice.RestockRequests_.CDS_NAME,
      service = cds.gen.catalogservice.CatalogService_.CDS_NAME)
  public void deriveCatalogSupplier(cds.gen.catalogservice.RestockRequests request) {
    deriveSupplierFromBook((CdsData) request);
  }

  private void applyCreateDefaults(CdsData request) {
    String id = (String) request.get("ID");
    if (id == null) {
      id = UUID.randomUUID().toString();
      request.put("ID", id);
    }
    if (request.get("requestId") == null) {
      request.put("requestId", "RR-" + id.substring(0, 8).toUpperCase());
    }
    request.put("receivedQty", 0);
    request.put("status", "Draft");
    request.putIfAbsent("priority", "Medium");
    request.putIfAbsent("requestedAt", Instant.now());
    request.putIfAbsent("expectedAt", Instant.now().plusSeconds(7L * 24 * 60 * 60));
    request.putIfAbsent("requesterId", "System");
    request.putIfAbsent("notes", "");
  }

  private void deriveSupplierFromBook(CdsData request) {
    if (!request.containsKey("book_ID")) {
      return;
    }

    String bookId = (String) request.get("book_ID");
    if (bookId == null) {
      request.put("supplier_ID", null);
      return;
    }

    Inventory inventory =
        persistenceService
            .run(
                Select.from(Inventory_.class)
                    .columns(i -> i.supplier_ID())
                    .where(i -> i.book_ID().eq(bookId))
                    .limit(1))
            .first(Inventory.class)
            .orElseThrow(
                () ->
                    new ServiceException(
                        ErrorStatuses.BAD_REQUEST,
                        "The selected book does not have an inventory supplier."));

    String supplierId = inventory.getSupplierId();
    Suppliers supplier =
        persistenceService
            .run(
                Select.from(Suppliers_.class)
                    .columns(s -> s.leadTimeDays())
                    .where(s -> s.ID().eq(supplierId))
                    .limit(1))
            .first(Suppliers.class)
            .orElseThrow(
                () ->
                    new ServiceException(
                        ErrorStatuses.BAD_REQUEST,
                        "The inventory supplier does not exist."));

    Instant requestedAt =
        request.get("requestedAt") instanceof Instant value ? value : Instant.now();
    request.put("supplier_ID", supplierId);
    request.put(
        "expectedAt",
        requestedAt.plusSeconds((long) supplier.getLeadTimeDays() * 24 * 60 * 60));
  }

  @Before(event = CqnService.EVENT_CREATE, entity = cds.gen.inventoryservice.RestockRequests_.CDS_NAME, service = InventoryService_.CDS_NAME)
  public void preventDuplicateInventoryOpenRequest(RestockRequests request) {
    preventDuplicateOpenRequest((CdsData) request);
  }

  @Before(event = CqnService.EVENT_CREATE, entity = cds.gen.catalogservice.RestockRequests_.CDS_NAME, service = cds.gen.catalogservice.CatalogService_.CDS_NAME)
  public void preventDuplicateCatalogOpenRequest(cds.gen.catalogservice.RestockRequests request) {
    preventDuplicateOpenRequest((CdsData) request);
  }

  private void preventDuplicateOpenRequest(CdsData request) {
    String bookId = (String) request.get("book_ID");
    String requestId = (String) request.get("ID");
    if (bookId == null) {
      return;
    }
    boolean duplicate =
        persistenceService
            .run(
                Select.from(RestockRequests_.class)
                    .columns(r -> r.ID())
                    .where(r -> r.book_ID().eq(bookId).and(r.status().in(OPEN_STATUSES)))
                    .limit(1))
            .first()
            .filter(row -> !row.get("ID").equals(requestId))
            .isPresent();
    if (duplicate) {
      throw new ServiceException(
          ErrorStatuses.CONFLICT,
          "This book already has an open restock request. Complete or reject it before creating another request.");
    }
  }

  @On(event = RestockRequestsSubmitContext.CDS_NAME, entity = cds.gen.inventoryservice.RestockRequests_.CDS_NAME, service = InventoryService_.CDS_NAME)
  public void submit(RestockRequestsSubmitContext context) {
    transition(context, context.getCqn(), "Draft", "Pending Review", "Submitted for Review", note(context.getNote()));
  }

  @On(event = cds.gen.catalogservice.RestockRequestsSubmitContext.CDS_NAME, entity = cds.gen.catalogservice.RestockRequests_.CDS_NAME, service = cds.gen.catalogservice.CatalogService_.CDS_NAME)
  public void submitCatalog(cds.gen.catalogservice.RestockRequestsSubmitContext context) {
    transition(context, context.getCqn(), "Draft", "Pending Review", "Submitted for Review", note(context.getNote()));
  }

  @On(event = RestockRequestsApproveContext.CDS_NAME, entity = cds.gen.inventoryservice.RestockRequests_.CDS_NAME, service = InventoryService_.CDS_NAME)
  public void approve(RestockRequestsApproveContext context) {
    transition(context, context.getCqn(), "Pending Review", "Approved", "Approved", note(context.getNote()));
  }

  @On(event = cds.gen.catalogservice.RestockRequestsApproveContext.CDS_NAME, entity = cds.gen.catalogservice.RestockRequests_.CDS_NAME, service = cds.gen.catalogservice.CatalogService_.CDS_NAME)
  public void approveCatalog(cds.gen.catalogservice.RestockRequestsApproveContext context) {
    transition(context, context.getCqn(), "Pending Review", "Approved", "Approved", note(context.getNote()));
  }

  @On(event = RestockRequestsRejectContext.CDS_NAME, entity = cds.gen.inventoryservice.RestockRequests_.CDS_NAME, service = InventoryService_.CDS_NAME)
  public void reject(RestockRequestsRejectContext context) {
    String reason = context.getReason() == null ? "" : context.getReason().trim();
    if (reason.isEmpty()) {
      throw new ServiceException(ErrorStatuses.BAD_REQUEST, "Enter a rejection reason.");
    }
    transition(context, context.getCqn(), "Pending Review", "Rejected", "Rejected", reason);
  }

  @On(event = cds.gen.catalogservice.RestockRequestsRejectContext.CDS_NAME, entity = cds.gen.catalogservice.RestockRequests_.CDS_NAME, service = cds.gen.catalogservice.CatalogService_.CDS_NAME)
  public void rejectCatalog(cds.gen.catalogservice.RestockRequestsRejectContext context) {
    String reason = context.getReason() == null ? "" : context.getReason().trim();
    if (reason.isEmpty()) {
      throw new ServiceException(ErrorStatuses.BAD_REQUEST, "Enter a rejection reason.");
    }
    transition(context, context.getCqn(), "Pending Review", "Rejected", "Rejected", reason);
  }

  @On(event = RestockRequestsMarkOrderedContext.CDS_NAME, entity = cds.gen.inventoryservice.RestockRequests_.CDS_NAME, service = InventoryService_.CDS_NAME)
  public void markOrdered(RestockRequestsMarkOrderedContext context) {
    transition(context, context.getCqn(), "Approved", "Ordered", "Marked as Ordered", note(context.getNote()));
  }

  @On(event = cds.gen.catalogservice.RestockRequestsMarkOrderedContext.CDS_NAME, entity = cds.gen.catalogservice.RestockRequests_.CDS_NAME, service = cds.gen.catalogservice.CatalogService_.CDS_NAME)
  public void markOrderedCatalog(cds.gen.catalogservice.RestockRequestsMarkOrderedContext context) {
    transition(context, context.getCqn(), "Approved", "Ordered", "Marked as Ordered", note(context.getNote()));
  }

  @On(event = RestockRequestsRecordReceiptContext.CDS_NAME, entity = cds.gen.inventoryservice.RestockRequests_.CDS_NAME, service = InventoryService_.CDS_NAME)
  public void recordReceipt(RestockRequestsRecordReceiptContext context) {
    recordReceipt(context, context.getCqn(), context.getQuantity(), note(context.getNote()));
  }

  @On(event = cds.gen.catalogservice.RestockRequestsRecordReceiptContext.CDS_NAME, entity = cds.gen.catalogservice.RestockRequests_.CDS_NAME, service = cds.gen.catalogservice.CatalogService_.CDS_NAME)
  public void recordCatalogReceipt(cds.gen.catalogservice.RestockRequestsRecordReceiptContext context) {
    recordReceipt(context, context.getCqn(), context.getQuantity(), note(context.getNote()));
  }

  private void recordReceipt(EventContext context, CqnSelect cqn, Integer receiptQuantity, String note) {
    int quantity = receiptQuantity == null ? 0 : receiptQuantity;
    cds.gen.bookshop.management.RestockRequests request = loadRequest(context, cqn);
    if (!("Ordered".equals(request.getStatus()) || "Partially Received".equals(request.getStatus()))) {
      invalidTransition(request.getStatus(), "record a receipt");
    }
    int remaining = request.getRequestedQty() - request.getReceivedQty();
    if (quantity <= 0 || quantity > remaining) {
      throw new ServiceException(
          ErrorStatuses.BAD_REQUEST,
          "Receipt quantity must be greater than zero and no more than the remaining quantity.");
    }

    int received = request.getReceivedQty() + quantity;
    String nextStatus = received == request.getRequestedQty() ? "Received" : "Partially Received";
    persistenceService.run(
        Update.entity(RestockRequests_.class)
            .data(Map.of("receivedQty", received, "status", nextStatus))
            .byId(request.getId()));
    receiveInventory(request, quantity);
    appendHistory(request, "Receipt Recorded", nextStatus, context, note);
    setResult(context, request.getId());
  }

  private void transition(
      EventContext context,
      CqnSelect cqn,
      String expectedStatus,
      String nextStatus,
      String action,
      String comment) {
    cds.gen.bookshop.management.RestockRequests request = loadRequest(context, cqn);
    if (!expectedStatus.equals(request.getStatus())) {
      invalidTransition(request.getStatus(), action.toLowerCase());
    }
    persistenceService.run(
        Update.entity(RestockRequests_.class).data("status", nextStatus).byId(request.getId()));
    appendHistory(request, action, nextStatus, context, comment);
    setResult(context, request.getId());
  }

  private cds.gen.bookshop.management.RestockRequests loadRequest(EventContext context, CqnSelect cqn) {
    Object id = CqnAnalyzer.create(context.getModel()).analyze(cqn).targetKeys().get("ID");
    if (id == null) {
      throw new ServiceException(ErrorStatuses.BAD_REQUEST, "The restock request ID is missing.");
    }
    return persistenceService
        .run(Select.from(RestockRequests_.class).byId(id).lock())
        .first(cds.gen.bookshop.management.RestockRequests.class)
        .orElseThrow(() -> new ServiceException(ErrorStatuses.NOT_FOUND, "Restock request not found."));
  }

  private void appendHistory(
      cds.gen.bookshop.management.RestockRequests request,
      String action,
      String status,
      EventContext context,
      String comment) {
    List<RestockHistory> entries =
        persistenceService
            .run(
                Select.from(RestockHistory_.class)
                    .columns(h -> h.sequence())
                    .where(h -> h.request_ID().eq(request.getId())))
            .listOf(RestockHistory.class);
    int sequence = entries.stream().map(RestockHistory::getSequence).max(Integer::compareTo).orElse(0) + 1;
    String id = UUID.randomUUID().toString();
    RestockHistory history = RestockHistory.create();
    history.setId(id);
    history.setHistoryId("H-" + id.substring(0, 8).toUpperCase());
    history.setRequestId(request.getId());
    history.setSequence(sequence);
    history.setAction(action);
    history.setStatus(status);
    history.setPerformedBy(context.getUserInfo().getName());
    history.setPerformedAt(Instant.now());
    history.setComment(comment == null ? "" : comment);
    persistenceService.run(Insert.into(RestockHistory_.class).entry(history));
  }

  private void receiveInventory(cds.gen.bookshop.management.RestockRequests request, int quantity) {
    Inventory inventory =
        persistenceService
            .run(
                Select.from(Inventory_.class)
                    .where(i -> i.book_ID().eq(request.getBookId()))
                    .lock())
            .single(Inventory.class);
    Books book =
        persistenceService
            .run(
                Select.from(Books_.class)
                    .columns(b -> b.ID(), b -> b.price())
                    .byId(request.getBookId()))
            .single(Books.class);

    inventory.setOnHand(inventory.getOnHand() + quantity);
    inventory.setLastCountedAt(Instant.now());
    BookHandler.updateDerivedInventory(inventory, book.getPrice());
    persistenceService.run(Update.entity(Inventory_.class).entry(inventory).byId(inventory.getId()));

    String movementUuid = UUID.randomUUID().toString();
    StockMovements movement = StockMovements.create();
    movement.setId(movementUuid);
    movement.setMovementId("M-" + movementUuid.substring(0, 8).toUpperCase());
    movement.setBookId(request.getBookId());
    movement.setMovementType("Receipt");
    movement.setQuantity(quantity);
    movement.setOccurredAt(Instant.now());
    movement.setReferenceId(request.getRequestId());
    persistenceService.run(Insert.into(StockMovements_.class).entry(movement));
  }

  private void setResult(EventContext context, String id) {
    if (context instanceof RestockRequestsSubmitContext submitContext) {
      submitContext.setResult(loadInventoryServiceRequest(context, id));
    } else if (context instanceof RestockRequestsApproveContext approveContext) {
      approveContext.setResult(loadInventoryServiceRequest(context, id));
    } else if (context instanceof RestockRequestsRejectContext rejectContext) {
      rejectContext.setResult(loadInventoryServiceRequest(context, id));
    } else if (context instanceof RestockRequestsMarkOrderedContext orderedContext) {
      orderedContext.setResult(loadInventoryServiceRequest(context, id));
    } else if (context instanceof RestockRequestsRecordReceiptContext receiptContext) {
      receiptContext.setResult(loadInventoryServiceRequest(context, id));
    } else if (context instanceof cds.gen.catalogservice.RestockRequestsSubmitContext submitContext) {
      submitContext.setResult(loadCatalogServiceRequest(context, id));
    } else if (context instanceof cds.gen.catalogservice.RestockRequestsApproveContext approveContext) {
      approveContext.setResult(loadCatalogServiceRequest(context, id));
    } else if (context instanceof cds.gen.catalogservice.RestockRequestsRejectContext rejectContext) {
      rejectContext.setResult(loadCatalogServiceRequest(context, id));
    } else if (context instanceof cds.gen.catalogservice.RestockRequestsMarkOrderedContext orderedContext) {
      orderedContext.setResult(loadCatalogServiceRequest(context, id));
    } else if (context instanceof cds.gen.catalogservice.RestockRequestsRecordReceiptContext receiptContext) {
      receiptContext.setResult(loadCatalogServiceRequest(context, id));
    }
  }

  private RestockRequests loadInventoryServiceRequest(EventContext context, String id) {
    return ((com.sap.cds.services.cds.CqnService) context.getService())
        .run(Select.from(cds.gen.inventoryservice.RestockRequests_.class)
            .where(r -> r.ID().eq(id).and(r.IsActiveEntity().eq(true))))
        .single(RestockRequests.class);
  }

  private cds.gen.catalogservice.RestockRequests loadCatalogServiceRequest(EventContext context, String id) {
    return ((com.sap.cds.services.cds.CqnService) context.getService())
        .run(Select.from(cds.gen.catalogservice.RestockRequests_.class)
            .where(r -> r.ID().eq(id).and(r.IsActiveEntity().eq(true))))
        .single(cds.gen.catalogservice.RestockRequests.class);
  }

  private void invalidTransition(String currentStatus, String action) {
    throw new ServiceException(
        ErrorStatuses.CONFLICT,
        "Cannot " + action + " while the restock request is in status " + currentStatus + ".");
  }

  private String note(String value) {
    return value == null ? "" : value.trim();
  }
}

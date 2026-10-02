using { cuid, managed } from '@sap/cds/common';

namespace bookshop.management;

type CurrencyCode : String(3) enum {
  USD;
}

type RestockPriority : String(20) enum {
  Low = 'Low';
  Medium = 'Medium';
  High = 'High';
  Urgent = 'Urgent';
}

type RestockStatus : String(30) enum {
  Draft = 'Draft';
  PendingReview = 'Pending Review';
  Approved = 'Approved';
  Rejected = 'Rejected';
  Ordered = 'Ordered';
  PartiallyReceived = 'Partially Received';
  Received = 'Received';
}

@assert.unique.authorId: [authorId]
entity Authors : cuid, managed {
  authorId    : String(6) not null;
  displayName : String(120) not null;
  countryCode : String(2) not null;
  biography   : LargeString not null;
  books       : Association to many Books on books.author = $self;
}

@assert.unique.categoryId: [categoryId]
entity Categories : cuid, managed {
  categoryId : String(6) not null;
  parent     : Association to Categories;
  name       : String(100) not null;
  level      : Integer not null @assert.range: [1, 10];
  sortOrder  : Integer not null @assert.range: [0, 9999];
  children   : Association to many Categories on children.parent = $self;
  books      : Association to many Books on books.category = $self;
}

@assert.unique.publisherId: [publisherId]
entity Publishers : cuid, managed {
  publisherId : String(6) not null;
  name        : String(120) not null;
  countryCode : String(2) not null;
  website     : String(500);
  books       : Association to many Books on books.publisher = $self;
}

@assert.unique.supplierId: [supplierId]
entity Suppliers : cuid, managed {
  supplierId        : String(6) not null;
  name              : String(120) not null;
  email             : String(180) not null;
  leadTimeDays      : Integer not null @assert.range: [0, 365];
  reliabilityPercent: Integer not null @assert.range: [0, 100];
}

@assert.unique.languageCode: [code]
entity Languages {
  key name : String(40);
  code     : String(5) not null;
  sortOrder: Integer not null @assert.range: [0, 9999];
}

entity AvailabilityStatuses {
  key name : String(20);
  sortOrder: Integer not null @assert.range: [0, 9999];
}

entity RestockStatuses {
  key code : String(30);
  name     : String(30) not null;
  sortOrder: Integer not null @assert.range: [0, 9999];
}

entity RestockPriorities {
  key code : String(20);
  name     : String(20) not null;
  sortOrder: Integer not null @assert.range: [0, 9999];
}

@assert.unique.bookId: [bookId]
@assert.unique.isbn13: [isbn13]
entity Books : cuid, managed {
  bookId          : String(12) not null;
  isbn13          : String(13) not null @assert.format: '^\d{13}$';
  title           : String(180) not null;
  author          : Association to Authors not null;
  category        : Association to Categories not null;
  publisher       : Association to Publishers not null;
  description     : LargeString not null;
  coverPath       : String(500);
  language        : String(40) not null default 'English';
  publicationDate : Date not null default '2026-10-01';
  pageCount       : Integer not null default 1 @assert.range: [1, 10000];
  price           : Decimal(12, 2) not null @assert.range: [0.01, 9999999999.99] @Measures.ISOCurrency: currency;
  currency        : CurrencyCode not null default 'USD';
  ratingAverage   : Decimal(3, 2);
  ratingCount     : Integer not null default 0 @assert.range: [0, 999999];
  initialStock    : Integer not null default 0 @assert.range: [0, 999999];
  reorderPoint    : Integer not null default 5 @assert.range: [0, 999999];
  inventory       : Association to one Inventory on inventory.book = $self;
  reviews         : Association to many Reviews on reviews.book = $self;
  stockMovements  : Association to many StockMovements on stockMovements.book = $self;
  restockRequests : Association to many RestockRequests on restockRequests.book = $self;
}

@assert.unique.inventoryBook: [book]
entity Inventory : cuid, managed {
  book            : Association to Books not null;
  supplier        : Association to Suppliers not null;
  storageLocation : String(20) not null;
  onHand          : Integer not null @assert.range: [0, 999999];
  reserved        : Integer not null @assert.range: [0, 999999];
  reorderPoint    : Integer not null @assert.range: [0, 999999];
  targetStock     : Integer not null @assert.range: [0, 999999];
  lastCountedAt   : Timestamp not null;
  available       : Integer not null;
  inventoryStatus: String(20) not null;
  inventoryStatusCriticality: Integer not null @assert.range: [1, 3];
  suggestedRestockQuantity: Integer not null @assert.range: [0, 999999];
  inventoryValue  : Decimal(16, 2) not null @Measures.ISOCurrency: currency;
  currency        : CurrencyCode not null default 'USD';
}

@assert.unique.movementId: [movementId]
entity StockMovements : cuid, managed {
  movementId  : String(10) not null;
  book        : Association to Books not null;
  movementType: String(30) not null;
  quantity    : Integer not null;
  occurredAt  : Timestamp not null;
  referenceId : String(30) not null;
}

@assert.unique.saleId: [saleId]
entity Sales : cuid {
  saleId      : String(10) not null;
  book        : Association to Books not null;
  salesMonth  : String(7) not null @assert.format: '^2026-(0[1-9]|10)$';
  soldAt      : Timestamp not null;
  quantity    : Integer not null @assert.range: [1, 999999];
  unitPrice   : Decimal(12, 2) not null @assert.range: [0.01, 9999999999.99] @Measures.ISOCurrency: currency;
  currency    : CurrencyCode not null default 'USD';
  netAmount   : Decimal(16, 2) not null @Measures.ISOCurrency: currency;
  channel     : String(30) not null;
}

@assert.unique.reviewId: [reviewId]
entity Reviews : cuid, managed {
  reviewId    : String(10) not null;
  book        : Association to Books not null;
  rating      : Integer not null @assert.range: [1, 5];
  reviewerName: String(120) not null;
  reviewedAt  : Timestamp not null;
  title       : String(180) not null;
  comment     : LargeString not null;
}

@assert.unique.requestId: [requestId]
entity RestockRequests : cuid, managed {
  requestId   : String(16) not null;
  book        : Association to Books not null;
  requestedQty: Integer not null @assert.range: [1, 999999];
  receivedQty : Integer not null default 0 @assert.range: [0, 999999];
  priority    : RestockPriority not null;
  status      : RestockStatus not null default 'Draft';
  supplier    : Association to Suppliers not null;
  requestedAt : Timestamp not null;
  expectedAt  : Timestamp not null;
  requesterId : String(100) not null;
  notes       : LargeString not null;
  history     : Composition of many RestockHistory on history.request = $self;
}

@assert.unique.historyId: [historyId]
@assert.unique.requestSequence: [request, sequence]
entity RestockHistory : cuid, managed {
  historyId  : String(12) not null;
  request    : Association to RestockRequests not null;
  sequence   : Integer not null @assert.range: [1, 9999];
  action     : String(50) not null;
  status     : String(30) not null;
  performedBy: String(100) not null;
  performedAt: Timestamp not null;
  comment    : LargeString not null;
}

@readonly
entity InventoryAttention as select from Inventory as inventory
  left join RestockRequests as request
    on request.book.ID = inventory.book.ID
    and request.status in ('Draft', 'Pending Review', 'Approved', 'Ordered', 'Partially Received')
  {
    key inventory.ID,
        inventory.book,
        inventory.supplier,
        inventory.storageLocation,
        inventory.onHand,
        inventory.reserved,
        inventory.reorderPoint,
        inventory.targetStock,
        inventory.lastCountedAt,
        inventory.available,
        inventory.inventoryStatus,
        inventory.inventoryStatusCriticality,
        inventory.suggestedRestockQuantity,
        inventory.inventoryValue,
        inventory.currency,
        inventory.modifiedAt,
        request.ID as restockRequest_ID,
        request.requestId,
        request.status as requestStatus,
        request.priority,
        request.expectedAt,
        case
          when request.status in ('Ordered', 'Partially Received') and request.expectedAt < $now then true
          else false
        end as isOverdue : Boolean,
        case
          when request.status in ('Ordered', 'Partially Received') and request.expectedAt < $now then 1
          when inventory.inventoryStatus = 'Out of Stock' then 2
          when inventory.inventoryStatus = 'Low Stock' then 3
          else 4
        end as attentionRank : Integer,
        case
          when request.ID is not null then true
          else false
        end as hasOpenRequest : Boolean,
        case
          when inventory.inventoryStatus in ('Low Stock', 'Out of Stock') then true
          when request.status in ('Ordered', 'Partially Received') and request.expectedAt < $now then true
          else false
        end as requiresAttention : Boolean,
        restockRequest : Association to one RestockRequests
          on restockRequest.ID = restockRequest_ID
  };

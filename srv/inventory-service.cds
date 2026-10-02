using { bookshop.management as db } from '../db/schema';

@path: 'inventory'
@requires: ['Viewer', 'CatalogManager', 'InventoryManager', 'Administrator']
service InventoryService {
  @readonly entity Inventory as projection on db.Inventory;
  @readonly entity Suppliers as projection on db.Suppliers;
  @readonly entity Books as projection on db.Books;
  @readonly entity StockMovements as projection on db.StockMovements;

  @odata.draft.enabled
  @restrict: [
    { grant: 'READ', to: ['Viewer', 'CatalogManager', 'InventoryManager', 'Administrator'] },
    { grant: '*', to: ['InventoryManager', 'Administrator'] }
  ]
  entity RestockRequests as projection on db.RestockRequests actions {
    action submit(note: String(1000) @title: '{i18n>commentLabel}') returns RestockRequests;
    action approve(note: String(1000) @title: '{i18n>commentLabel}') returns RestockRequests;
    action reject(reason: String(500)) returns RestockRequests;
    action markOrdered(note: String(1000) @title: '{i18n>commentLabel}') returns RestockRequests;
    action recordReceipt(quantity: Integer, note: String(1000) @title: '{i18n>commentLabel}') returns RestockRequests;
  };

  @readonly entity RestockHistory as projection on db.RestockHistory;
}

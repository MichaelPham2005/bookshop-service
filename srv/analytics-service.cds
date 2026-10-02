using { bookshop.management as db } from '../db/schema';

@path: 'analytics'
@requires: ['Viewer', 'CatalogManager', 'InventoryManager', 'Administrator']
service AnalyticsService {
  @readonly entity Sales as projection on db.Sales;
  @readonly entity Books as projection on db.Books;
  @readonly entity Authors as projection on db.Authors;
  @readonly entity Categories as projection on db.Categories;
  @readonly entity Inventory as projection on db.Inventory;
  @readonly entity StockMovements as projection on db.StockMovements;
  @readonly entity Reviews as projection on db.Reviews;
}

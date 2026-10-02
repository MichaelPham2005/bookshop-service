using { bookshop.management as db } from '../db/schema';
using { sap.common.Countries as CommonCountries } from '@sap/cds/common';

@path: 'bookshop'
@requires: ['Viewer', 'CatalogManager', 'InventoryManager', 'Administrator']
service CatalogService {
  @odata.draft.enabled
  @cds.redirection.target
  @restrict: [
    { grant: 'READ', to: ['Viewer', 'CatalogManager', 'InventoryManager', 'Administrator'] },
    { grant: ['CREATE', 'UPDATE', 'DELETE'], to: ['CatalogManager', 'Administrator'] }
  ]
  entity Books as projection on db.Books {
    *,
    virtual null as unitsSold : Integer,
    virtual null as salesRevenue : Decimal(16, 2)
  };

  @odata.draft.enabled
  @cds.search: { displayName, authorId, countryCode, biography }
  @restrict: [
    { grant: 'READ', to: ['Viewer', 'CatalogManager', 'InventoryManager', 'Administrator'] },
    { grant: ['CREATE', 'UPDATE', 'DELETE'], to: 'Administrator' }
  ]
  entity Authors as projection on db.Authors {
    *,
    virtual null as countryName : String(100),
    virtual null as bookCount : Integer
  };
  @readonly @cds.odata.valuelist @cds.redirection.target: false
  entity AuthorValueHelp as projection on db.Authors {
    key ID,
        authorId,
        displayName
  };
  @restrict: [
    { grant: 'READ', to: ['Viewer', 'CatalogManager', 'InventoryManager', 'Administrator'] },
    { grant: ['CREATE', 'DELETE'], to: 'Administrator' }
  ]
  entity Categories as projection on db.Categories;
  @readonly @cds.odata.valuelist entity Publishers as projection on db.Publishers;
  @readonly @cds.odata.valuelist entity Suppliers as projection on db.Suppliers;
  @readonly entity Languages as projection on db.Languages;
  @readonly entity AvailabilityStatuses as projection on db.AvailabilityStatuses;
  @readonly @cds.odata.valuelist entity RestockStatuses as projection on db.RestockStatuses;
  @readonly @cds.odata.valuelist entity RestockPriorities as projection on db.RestockPriorities;
  @readonly entity Countries as projection on CommonCountries;
  @readonly entity Inventory as projection on db.Inventory;
  @readonly entity Reviews as projection on db.Reviews;
  @readonly entity StockMovements as projection on db.StockMovements {
    *,
    coalesce(createdBy, 'System') as performedBy : String(255)
  };

  @readonly entity InventoryAttention as projection on db.InventoryAttention;

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

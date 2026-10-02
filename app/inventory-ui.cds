using { CatalogService } from '../srv/catalog-service';

annotate CatalogService.InventoryAttention with @(
  UI.HeaderInfo: {
    TypeName: '{i18n>inventoryItemTypeName}',
    TypeNamePlural: '{i18n>inventoryAttentionTitle}',
    Title: { Value: book.title },
    Description: { Value: book.bookId },
    TypeImageUrl: 'sap-icon://product'
  },
  UI.SelectionFields: [
    inventoryStatus,
    requestStatus,
    priority,
    supplier.name
  ],
  UI.PresentationVariant: {
    SortOrder: [
      { Property: attentionRank, Descending: false },
      { Property: available, Descending: false },
      { Property: book.title, Descending: false }
    ],
    Visualizations: ['@UI.LineItem']
  },
  UI.SelectionVariant#AllInventory: { Text: '{i18n>allInventoryView}' },
  UI.SelectionVariant#NeedsAttention: {
    Text: '{i18n>needsAttentionView}',
    SelectOptions: [{
      PropertyName: requiresAttention,
      Ranges: [{ Sign: #I, Option: #EQ, Low: true }]
    }]
  },
  UI.SelectionVariant#OutOfStock: {
    Text: '{i18n>outOfStockView}',
    SelectOptions: [{
      PropertyName: inventoryStatus,
      Ranges: [{ Sign: #I, Option: #EQ, Low: 'Out of Stock' }]
    }]
  },
  UI.SelectionVariant#LowStock: {
    Text: '{i18n>lowStockView}',
    SelectOptions: [{
      PropertyName: inventoryStatus,
      Ranges: [{ Sign: #I, Option: #EQ, Low: 'Low Stock' }]
    }]
  },
  UI.SelectionVariant#OpenRequests: {
    Text: '{i18n>openRequestsView}',
    SelectOptions: [{
      PropertyName: hasOpenRequest,
      Ranges: [{ Sign: #I, Option: #EQ, Low: true }]
    }]
  },
  UI.SelectionVariant#Overdue: {
    Text: '{i18n>overdueView}',
    SelectOptions: [{
      PropertyName: isOverdue,
      Ranges: [{ Sign: #I, Option: #EQ, Low: true }]
    }]
  },
  UI.LineItem: [
    { Value: book.title, Label: '{i18n>bookLabel}', ![@UI.Importance]: #High },
    { Value: book.bookId, Label: '{i18n>bookCodeLabel}', ![@UI.Importance]: #Medium },
    { Value: available, Label: '{i18n>availableStockLabel}', Criticality: inventoryStatusCriticality, ![@UI.Importance]: #High },
    { Value: targetStock, Label: '{i18n>targetStockLabel}', ![@UI.Importance]: #Medium },
    { Value: inventoryStatus, Label: '{i18n>inventoryStatusLabel}', Criticality: inventoryStatusCriticality, ![@UI.Importance]: #High },
    { Value: suggestedRestockQuantity, Label: '{i18n>suggestedQuantityLabel}', ![@UI.Importance]: #Medium },
    { Value: requestId, Label: '{i18n>requestIdLabel}', ![@UI.Importance]: #High },
    { Value: requestStatus, Label: '{i18n>requestStatusLabel}', ![@UI.Importance]: #High },
    { Value: priority, Label: '{i18n>priorityLabel}', ![@UI.Importance]: #Medium },
    { Value: supplier.name, Label: '{i18n>supplierLabel}', ![@UI.Importance]: #Medium },
    { Value: expectedAt, Label: '{i18n>expectedDateLabel}', Criticality: isOverdue, ![@UI.Importance]: #High },
    { Value: onHand, Label: '{i18n>onHandLabel}', ![@UI.Importance]: #Low },
    { Value: reserved, Label: '{i18n>reservedLabel}', ![@UI.Importance]: #Low },
    { Value: reorderPoint, Label: '{i18n>reorderPointLabel}', ![@UI.Importance]: #Low },
    { Value: storageLocation, Label: '{i18n>storageLocationLabel}', ![@UI.Importance]: #Low },
    { Value: lastCountedAt, Label: '{i18n>lastCountedAtLabel}', ![@UI.Importance]: #Low },
    { Value: modifiedAt, Label: '{i18n>lastUpdatedLabel}', ![@UI.Importance]: #Low },
    { Value: inventoryValue, Label: '{i18n>inventoryValueLabel}', ![@UI.Importance]: #Low },
    { Value: currency, Label: '{i18n>currencyLabel}', ![@UI.Importance]: #Low }
  ]
);

annotate CatalogService.InventoryAttention with {
  ID                       @UI.Hidden;
  restockRequest_ID        @UI.Hidden;
  attentionRank            @UI.Hidden @UI.HiddenFilter;
  requiresAttention        @UI.Hidden @UI.HiddenFilter;
  hasOpenRequest           @UI.Hidden @UI.HiddenFilter;
  isOverdue                @UI.Hidden @UI.HiddenFilter;
  inventoryStatus          @(title: '{i18n>inventoryStatusLabel}', Common.ValueListWithFixedValues: true, Common.ValueList: { CollectionPath: 'AvailabilityStatuses', Parameters: [{ $Type: 'Common.ValueListParameterInOut', LocalDataProperty: inventoryStatus, ValueListProperty: 'name' }] });
  requestStatus            @(
    title: '{i18n>requestStatusLabel}',
    Common.ValueListWithFixedValues: true,
    Common.ValueList: {
      CollectionPath: 'RestockStatuses',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: requestStatus, ValueListProperty: 'name' }
      ]
    }
  );
  priority                 @(
    title: '{i18n>priorityLabel}',
    Common.ValueListWithFixedValues: true,
    Common.ValueList: {
      CollectionPath: 'RestockPriorities',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: priority, ValueListProperty: 'name' }
      ]
    }
  );
  supplier                 @(title: '{i18n>supplierLabel}', Common.Text: supplier.name, Common.TextArrangement: #TextOnly, Common.FieldControl: #ReadOnly);
  storageLocation          @title: '{i18n>storageLocationLabel}';
  expectedAt               @title: '{i18n>expectedDateLabel}';
  currency                 @title: '{i18n>currencyLabel}' @readonly;
};

annotate CatalogService.InventoryAttention with @Capabilities.FilterRestrictions: {
  FilterExpressionRestrictions: [
    { Property: requestStatus, AllowedExpressions: 'MultiValue' },
    { Property: priority, AllowedExpressions: 'MultiValue' },
    { Property: supplier.name, AllowedExpressions: 'MultiValue' }
  ]
};

annotate CatalogService.Suppliers with {
  ID           @UI.Hidden;
  supplierId   @title: '{i18n>supplierCodeLabel}';
  name         @(
    title: '{i18n>supplierLabel}',
    Common.ValueList: {
      CollectionPath: 'Suppliers',
      Parameters: [
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'supplierId' },
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: name, ValueListProperty: 'name' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'email' }
      ]
    }
  );
  email        @title: '{i18n>emailLabel}';
  leadTimeDays @title: '{i18n>leadTimeLabel}';
  reliabilityPercent @UI.Hidden;
};

annotate CatalogService.RestockStatuses with @UI.PresentationVariant: {
  SortOrder: [{ Property: sortOrder, Descending: false }]
};

annotate CatalogService.RestockPriorities with @UI.PresentationVariant: {
  SortOrder: [{ Property: sortOrder, Descending: false }]
};

annotate CatalogService.RestockRequests with @(
  Common.SemanticKey: [requestId],
  UI.HeaderInfo: {
    TypeName: '{i18n>restockRequestTypeName}',
    TypeNamePlural: '{i18n>restockRequestTypeNamePlural}',
    Title: { Value: requestId },
    Description: { Value: book.title },
    TypeImageUrl: 'sap-icon://product'
  },
  UI.DataPoint#Status: { Value: status, Title: '{i18n>requestStatusLabel}' },
  UI.DataPoint#Priority: { Value: priority, Title: '{i18n>priorityLabel}' },
  UI.DataPoint#Requested: { Value: requestedQty, Title: '{i18n>requestedQuantityLabel}' },
  UI.DataPoint#Received: { Value: receivedQty, Title: '{i18n>receivedQuantityLabel}' },
  UI.DataPoint#Expected: { Value: expectedAt, Title: '{i18n>expectedDateLabel}' },
  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Status' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Priority' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Requested' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Received' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Expected' }
  ],
  UI.FieldGroup#Request: {
    Data: [
      { Value: requestId },
      { Value: book_ID },
      { Value: requestedQty },
      { Value: receivedQty },
      { Value: priority },
      { Value: status },
      { Value: requesterId }
    ]
  },
  UI.FieldGroup#Delivery: {
    Data: [
      { Value: supplier_ID },
      { Value: supplier.leadTimeDays, Label: '{i18n>leadTimeLabel}', ![@UI.Importance]: #Medium },
      { Value: requestedAt },
      { Value: expectedAt, ![@UI.Importance]: #High }
    ]
  },
  UI.FieldGroup#Notes: { Data: [{ Value: notes }] },
  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', ID: 'RequestDetails', Label: '{i18n>requestDetailsSection}', Target: '@UI.FieldGroup#Request' },
    { $Type: 'UI.ReferenceFacet', ID: 'Delivery', Label: '{i18n>supplierDeliverySection}', Target: '@UI.FieldGroup#Delivery' },
    { $Type: 'UI.ReferenceFacet', ID: 'History', Label: '{i18n>historySection}', Target: 'history/@UI.PresentationVariant' },
    { $Type: 'UI.ReferenceFacet', ID: 'Notes', Label: '{i18n>notesSection}', Target: '@UI.FieldGroup#Notes' }
  ],
  UI.Identification: [
    { $Type: 'UI.DataFieldForAction', Action: 'CatalogService.submit', Label: '{i18n>submitAction}' },
    { $Type: 'UI.DataFieldForAction', Action: 'CatalogService.approve', Label: '{i18n>approveAction}' },
    { $Type: 'UI.DataFieldForAction', Action: 'CatalogService.reject', Label: '{i18n>rejectAction}' },
    { $Type: 'UI.DataFieldForAction', Action: 'CatalogService.markOrdered', Label: '{i18n>markOrderedAction}' },
    { $Type: 'UI.DataFieldForAction', Action: 'CatalogService.recordReceipt', Label: '{i18n>recordReceiptAction}' }
  ]
);

annotate CatalogService.RestockRequests with {
  ID           @UI.Hidden;
  requestId    @title: '{i18n>requestIdLabel}' @readonly;
  book         @(title: '{i18n>bookLabel}', Common.Text: book.title, Common.TextArrangement: #TextOnly, Common.FieldControl: (status = 'Draft' ? 7 : 1));
  supplier     @(title: '{i18n>supplierLabel}', Common.Text: supplier.name, Common.TextArrangement: #TextOnly, Common.FieldControl: #ReadOnly);
  requestedQty @title: '{i18n>requestedQuantityLabel}' @Common.FieldControl: (status = 'Draft' ? 7 : 1);
  receivedQty  @title: '{i18n>receivedQuantityLabel}' @readonly;
  priority     @title: '{i18n>priorityLabel}' @Common.FieldControl: (status = 'Draft' ? 7 : 1);
  status       @title: '{i18n>requestStatusLabel}' @readonly;
  requestedAt  @title: '{i18n>requestedDateLabel}' @readonly;
  expectedAt   @title: '{i18n>expectedDateLabel}' @Common.FieldControl: (status = 'Draft' ? 7 : 1);
  requesterId  @title: '{i18n>requesterLabel}' @readonly;
  notes        @title: '{i18n>notesLabel}' @UI.MultiLineText @Common.FieldControl: #Optional;
};

annotate CatalogService.RestockRequests with @(
  Capabilities.DeleteRestrictions.Deletable: false,
  Capabilities.UpdateRestrictions.Updatable: true,
  Capabilities.NavigationRestrictions.RestrictedProperties: [{
    NavigationProperty: history,
    InsertRestrictions: { Insertable: false },
    UpdateRestrictions: { Updatable: false },
    DeleteRestrictions: { Deletable: false }
  }]
);

annotate CatalogService.RestockRequests with @Common.SideEffects#BookSelection: {
  SourceProperties: ['book_ID'],
  TargetProperties: ['supplier_ID', 'expectedAt'],
  TargetEntities: ['supplier']
};

annotate CatalogService.RestockRequests with {
  book @(
    Common.ValueList: {
      CollectionPath: 'Books',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: book_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'bookId' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'title' }
      ]
    }
  );
  supplier @(
    Common.ValueList: {
      CollectionPath: 'Suppliers',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: supplier_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'supplierId' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'leadTimeDays' }
      ]
    }
  );
};

annotate CatalogService.RestockHistory with @(
  UI.PresentationVariant: {
    SortOrder: [{ Property: sequence, Descending: false }],
    Visualizations: ['@UI.LineItem']
  },
  UI.LineItem: [
    { Value: sequence, Label: '{i18n>sequenceLabel}', ![@UI.Importance]: #Medium },
    { Value: action, Label: '{i18n>actionLabel}', ![@UI.Importance]: #High },
    { Value: status, Label: '{i18n>requestStatusLabel}', ![@UI.Importance]: #High },
    { Value: performedBy, Label: '{i18n>performedByLabel}', ![@UI.Importance]: #Medium },
    { Value: performedAt, Label: '{i18n>performedAtLabel}', ![@UI.Importance]: #High },
    { Value: comment, Label: '{i18n>commentLabel}', ![@UI.Importance]: #Medium }
  ]
);

annotate CatalogService.RestockRequests actions {
  submit @(
    Core.OperationAvailable: { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'Draft' ] } },
    Common.SideEffects: { TargetProperties: ['in/status'], TargetEntities: ['in/history'] }
  );
  approve @(
    Core.OperationAvailable: { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'Pending Review' ] } },
    Common.SideEffects: { TargetProperties: ['in/status'], TargetEntities: ['in/history'] }
  );
  reject @(
    Core.OperationAvailable: { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'Pending Review' ] } },
    Common.SideEffects: { TargetProperties: ['in/status'], TargetEntities: ['in/history'] }
  );
  markOrdered @(
    Core.OperationAvailable: { $edmJson: { $Eq: [ { $Path: 'in/status' }, 'Approved' ] } },
    Common.SideEffects: { TargetProperties: ['in/status'], TargetEntities: ['in/history'] }
  );
  recordReceipt @(
    Core.OperationAvailable: { $edmJson: { $Or: [
      { $Eq: [ { $Path: 'in/status' }, 'Ordered' ] },
      { $Eq: [ { $Path: 'in/status' }, 'Partially Received' ] }
    ] } },
    Common.SideEffects: {
      TargetProperties: ['in/status', 'in/receivedQty'],
      TargetEntities: ['in/history']
    }
  );
};

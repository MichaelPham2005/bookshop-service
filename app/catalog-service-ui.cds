using { CatalogService } from '../srv/catalog-service';

annotate CatalogService.Books with @(
  Common.SemanticKey: [bookId],
  UI.HeaderInfo: {
    TypeName: '{i18n>bookTypeName}',
    TypeNamePlural: '{i18n>bookTypeNamePlural}',
    Title: { Value: title },
    Description: { Value: author.displayName },
    TypeImageUrl: 'sap-icon://product'
  },
  UI.SelectionFields: [
    category.name,
    author.displayName,
    language,
    inventory.inventoryStatus
  ],
  UI.PresentationVariant: {
    SortOrder: [{ Property: title, Descending: false }],
    Visualizations: ['@UI.LineItem']
  },
  UI.DataPoint#Rating: {
    Value: ratingAverage,
    Visualization: #Rating,
    TargetValue: 5
  },
  UI.DataPoint#Price: {
    Value: price,
    Title: '{i18n>priceLabel}'
  },
  UI.DataPoint#UnitsSold: {
    Value: unitsSold,
    Title: '{i18n>unitsSoldLabel}'
  },
  UI.DataPoint#SalesRevenue: {
    Value: salesRevenue,
    Title: '{i18n>salesRevenueLabel}'
  },
  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Price' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Rating' },
    { $Type: 'UI.ReferenceFacet', Target: 'inventory/@UI.DataPoint#Availability' },
    { $Type: 'UI.ReferenceFacet', Target: 'inventory/@UI.DataPoint#AvailableStock' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#UnitsSold' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#SalesRevenue' }
  ],
  UI.FieldGroup#Catalog: {
    Data: [
      { Value: title },
      { Value: isbn13 },
      { Value: author_ID },
      { Value: category_ID },
      { Value: publisher_ID }
    ]
  },
  UI.FieldGroup#Publication: {
    Data: [
      { Value: language },
      { Value: publicationDate },
      { Value: pageCount },
      { Value: description }
    ]
  },
  UI.FieldGroup#Commercial: {
    Data: [
      { Value: price },
      { Value: currency },
      { Value: unitsSold },
      { Value: salesRevenue },
      { Value: initialStock },
      { Value: reorderPoint }
    ]
  },
  UI.Facets: [
    {
      $Type: 'UI.CollectionFacet',
      ID: 'Overview',
      Label: '{i18n>overviewSectionLabel}',
      Facets: [
        { $Type: 'UI.ReferenceFacet', ID: 'Catalog', Label: '{i18n>catalogSectionLabel}', Target: '@UI.FieldGroup#Catalog' },
        { $Type: 'UI.ReferenceFacet', ID: 'Publication', Label: '{i18n>publicationSectionLabel}', Target: '@UI.FieldGroup#Publication' },
        { $Type: 'UI.ReferenceFacet', ID: 'Commercial', Label: '{i18n>commercialSectionLabel}', Target: '@UI.FieldGroup#Commercial' }
      ]
    },
    { $Type: 'UI.ReferenceFacet', ID: 'Inventory', Label: '{i18n>inventorySectionLabel}', Target: 'inventory/@UI.FieldGroup#Details' },
    { $Type: 'UI.ReferenceFacet', ID: 'Reviews', Label: '{i18n>reviewsSectionLabel}', Target: 'reviews/@UI.LineItem' },
    { $Type: 'UI.ReferenceFacet', ID: 'StockMovements', Label: '{i18n>stockMovementsSectionLabel}', Target: 'stockMovements/@UI.LineItem' }
  ],
  UI.LineItem: [
    { Value: title, Label: '{i18n>bookLabel}', ![@UI.Importance]: #High },
    { Value: author.displayName, Label: '{i18n>authorLabel}', ![@UI.Importance]: #High },
    { Value: isbn13, Label: '{i18n>isbnLabel}', ![@UI.Importance]: #Medium },
    { Value: category.name, Label: '{i18n>categoryLabel}', ![@UI.Importance]: #High },
    { Value: language, Label: '{i18n>languageLabel}', ![@UI.Importance]: #Medium },
    { Value: publicationDate, Label: '{i18n>publicationDateLabel}', ![@UI.Importance]: #Medium },
    { Value: price, Label: '{i18n>priceLabel}', ![@UI.Importance]: #High , @Measures.ISOCurrency: currency},
    { Value: unitsSold, Label: '{i18n>unitsSoldLabel}', ![@UI.Importance]: #Medium },
    { Value: salesRevenue, Label: '{i18n>salesRevenueLabel}', ![@UI.Importance]: #Medium },
    {
      $Type: 'UI.DataFieldForAnnotation',
      Target: '@UI.DataPoint#Rating',
      Label: '{i18n>ratingLabel}',
      ![@UI.Importance]: #High
    },
    {
      Value: inventory.inventoryStatus,
      Criticality: inventory.inventoryStatusCriticality,
      ![@UI.Importance]: #High
    },
    { Value: inventory.available, Label: '{i18n>availableStockLabel}', ![@UI.Importance]: #High },
    { Value: inventory.supplier.name, Label: '{i18n>supplierLabel}', ![@UI.Importance]: #Low },
    { Value: modifiedAt, Label: '{i18n>lastUpdatedLabel}', ![@UI.Importance]: #Low }
  ]
);

annotate CatalogService.Books with {
  ID              @UI.Hidden;
  bookId          @UI.Hidden;
  title           @title: '{i18n>titleLabel}' @mandatory;
  isbn13          @title: '{i18n>isbnLabel}' @mandatory;
  author          @title: '{i18n>authorLabel}' @mandatory;
  category        @title: '{i18n>categoryLabel}' @mandatory;
  publisher       @title: '{i18n>publisherLabel}' @mandatory;
  description     @title: '{i18n>descriptionLabel}' @UI.MultiLineText;
  coverPath       @UI.Hidden;
  language        @(
    title: '{i18n>languageLabel}',
    Common.ValueListWithFixedValues: true,
    Common.ValueList: {
      CollectionPath: 'Languages',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: language, ValueListProperty: 'name' }
      ]
    }
  );
  publicationDate @title: '{i18n>publicationDateLabel}';
  pageCount       @title: '{i18n>pageCountLabel}';
  price           @title: '{i18n>priceLabel}';
  currency        @title: '{i18n>currencyLabel}' @readonly;
  ratingAverage   @title: '{i18n>ratingLabel}' @readonly;
  ratingCount     @readonly;
  initialStock    @title: '{i18n>initialStockLabel}' @mandatory;
  reorderPoint    @title: '{i18n>reorderPointLabel}' @mandatory;
  unitsSold       @title: '{i18n>unitsSoldLabel}' @readonly;
  salesRevenue    @title: '{i18n>salesRevenueLabel}' @readonly @Measures.ISOCurrency: currency;
};

annotate CatalogService.Inventory with {
  inventoryStatus @(
    title: '{i18n>availabilityLabel}',
    Common.ValueListWithFixedValues: true,
    Common.ValueList: {
      CollectionPath: 'AvailabilityStatuses',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: inventoryStatus, ValueListProperty: 'name' }
      ]
    }
  );
};

annotate CatalogService.Books with @Capabilities.FilterRestrictions: {
  FilterExpressionRestrictions: [
    { Property: language, AllowedExpressions: 'MultiValue' },
    { Property: inventory.inventoryStatus, AllowedExpressions: 'MultiValue' }
  ]
};

annotate CatalogService.Books with {
  category @(
    Common.Text: category.name,
    Common.TextArrangement: #TextOnly,
    Common.ValueList: {
      CollectionPath: 'Categories',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: category_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'categoryId' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
      ]
    }
  );
  author @(
    Common.Text: author.displayName,
    Common.TextArrangement: #TextOnly,
    Common.ValueList: {
      CollectionPath: 'AuthorValueHelp',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: author_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'authorId' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'displayName' }
      ]
    }
  );
  publisher @(
    Common.Text: publisher.name,
    Common.TextArrangement: #TextOnly,
    Common.ValueList: {
      CollectionPath: 'Publishers',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: publisher_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'publisherId' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'countryCode' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'website' }
      ]
    }
  );
};

annotate CatalogService.AuthorValueHelp with @(
  UI.HeaderInfo: { TypeName: '{i18n>authorLabel}', TypeNamePlural: '{i18n>authorsLabel}', Title: { Value: displayName } },
  UI.LineItem: [
    { Value: authorId, Label: '{i18n>authorCodeLabel}' },
    { Value: displayName, Label: '{i18n>authorNameLabel}' }
  ]
);
annotate CatalogService.AuthorValueHelp with {
  ID          @UI.Hidden;
  authorId    @title: '{i18n>authorCodeLabel}';
  displayName @title: '{i18n>authorNameLabel}';
};

annotate CatalogService.Inventory with @(
  UI.DataPoint#Availability: {
    Value: inventoryStatus,
    Title: '{i18n>availabilityLabel}',
    Criticality: inventoryStatusCriticality
  },
  UI.DataPoint#AvailableStock: {
    Value: available,
    Title: '{i18n>availableStockLabel}'
  },
  UI.FieldGroup#Details: {
    Data: [
      { Value: inventoryStatus },
      { Value: onHand },
      { Value: reserved },
      { Value: available },
      { Value: reorderPoint },
      { Value: targetStock },
      { Value: storageLocation },
      { Value: supplier.name },
      { Value: lastCountedAt },
      { Value: inventoryValue },
      { Value: currency }
    ]
  }
);

annotate CatalogService.Inventory with {
  onHand          @title: '{i18n>onHandLabel}';
  reserved        @title: '{i18n>reservedLabel}';
  available       @title: '{i18n>availableStockLabel}';
  reorderPoint    @title: '{i18n>reorderPointLabel}';
  targetStock     @title: '{i18n>targetStockLabel}';
  storageLocation @title: '{i18n>storageLocationLabel}';
  lastCountedAt   @title: '{i18n>lastCountedAtLabel}';
  inventoryValue  @title: '{i18n>inventoryValueLabel}';
  currency        @title: '{i18n>currencyLabel}';
};

annotate CatalogService.Reviews with @UI.LineItem: [
  { Value: rating, Label: '{i18n>ratingLabel}' },
  { Value: reviewerName, Label: '{i18n>reviewerLabel}' },
  { Value: reviewedAt, Label: '{i18n>reviewDateLabel}' },
  { Value: title, Label: '{i18n>reviewTitleLabel}' },
  { Value: comment, Label: '{i18n>commentLabel}' }
];

annotate CatalogService.StockMovements with @UI.LineItem: [
  { Value: occurredAt, Label: '{i18n>occurredAtLabel}' },
  { Value: movementType, Label: '{i18n>movementTypeLabel}' },
  { Value: quantity, Label: '{i18n>quantityLabel}' },
  { Value: referenceId, Label: '{i18n>referenceLabel}' },
  { Value: performedBy, Label: '{i18n>performedByLabel}' }
];

annotate CatalogService.Authors with @(
  Common.SemanticKey: [authorId],
  UI.HeaderInfo: {
    TypeName: '{i18n>authorLabel}',
    TypeNamePlural: '{i18n>authorsLabel}',
    Title: { Value: displayName },
    TypeImageUrl: 'sap-icon://person-placeholder'
  },
  UI.SelectionFields: [displayName, countryCode],
  UI.PresentationVariant: {
    SortOrder: [{ Property: displayName, Descending: false }],
    Visualizations: ['@UI.LineItem']
  },
  UI.DataPoint#AuthorCode: {
    Value: authorId,
    Title: '{i18n>authorCodeLabel}',
    Criticality: #Information
  },
  UI.DataPoint#BookCount: {
    Value: bookCount,
    Title: '{i18n>bookCountLabel}',
    Criticality: #Positive
  },
  UI.DataPoint#AuthorCountry: {
    Value: countryName,
    Title: '{i18n>countryLabel}',
    Criticality: #Information
  },
  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#AuthorCode' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#AuthorCountry' },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#BookCount' }
  ],
  UI.FieldGroup#Details: {
    Data: [
      { Value: displayName },
      { Value: countryCode },
      { Value: biography }
    ]
  },
  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', ID: 'AuthorDetails', Label: '{i18n>authorInformationSectionLabel}', Target: '@UI.FieldGroup#Details' },
    { $Type: 'UI.ReferenceFacet', ID: 'AuthorBooks', Label: '{i18n>booksSectionLabel}', Target: 'books/@UI.LineItem#AuthorBooks' }
  ],
  UI.LineItem: [
    { Value: displayName, Label: '{i18n>authorNameLabel}', ![@UI.Importance]: #High },
    { Value: authorId, Label: '{i18n>authorCodeLabel}', ![@UI.Importance]: #High },
    { Value: countryName, Label: '{i18n>countryLabel}', ![@UI.Importance]: #High },
    { Value: bookCount, Label: '{i18n>bookCountLabel}', ![@UI.Importance]: #High },
    { Value: modifiedAt, Label: '{i18n>lastUpdatedLabel}', ![@UI.Importance]: #Medium }
  ]
);
annotate CatalogService.Authors with {
  ID          @UI.Hidden;
  authorId    @title: '{i18n>authorCodeLabel}' @readonly;
  displayName @title: '{i18n>authorNameLabel}' @mandatory;
  countryCode @(
    title: '{i18n>countryLabel}',
    mandatory,
    Common.Text: countryName,
    Common.TextArrangement: #TextOnly,
    Common.ValueListWithFixedValues: true,
    Common.ValueList: {
      CollectionPath: 'Countries',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: countryCode, ValueListProperty: 'code' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
      ]
    }
  );
  countryName @UI.HiddenFilter @readonly;
  biography   @title: '{i18n>biographyLabel}' @UI.MultiLineText;
  bookCount   @title: '{i18n>bookCountLabel}' @readonly;
};

annotate CatalogService.Authors with @Capabilities.NavigationRestrictions: {
  RestrictedProperties: [{
    NavigationProperty: books,
    InsertRestrictions: { Insertable: false },
    UpdateRestrictions: { Updatable: false },
    DeleteRestrictions: { Deletable: false }
  }]
};

annotate CatalogService.Books with @UI.LineItem#AuthorBooks: [
  { Value: bookId, Label: '{i18n>bookCodeLabel}', ![@UI.Importance]: #Medium },
  { Value: title, Label: '{i18n>titleLabel}', ![@UI.Importance]: #High },
  { Value: category.name, Label: '{i18n>categoryLabel}', ![@UI.Importance]: #High },
  { Value: publisher.name, Label: '{i18n>publisherLabel}', ![@UI.Importance]: #Medium },
  { Value: language, Label: '{i18n>languageLabel}', ![@UI.Importance]: #Medium },
  { Value: publicationDate, Label: '{i18n>publicationDateLabel}', ![@UI.Importance]: #Medium },
  { Value: unitsSold, Label: '{i18n>unitsSoldLabel}', ![@UI.Importance]: #High },
  { Value: salesRevenue, Label: '{i18n>salesRevenueLabel}', ![@UI.Importance]: #Medium },
  {
    $Type: 'UI.DataFieldForAnnotation',
    Target: '@UI.DataPoint#Rating',
    Label: '{i18n>ratingLabel}',
    ![@UI.Importance]: #High
  },
  {
    Value: inventory.inventoryStatus,
    Label: '{i18n>availabilityLabel}',
    Criticality: inventory.inventoryStatusCriticality,
    ![@UI.Importance]: #High
  }
];

annotate CatalogService.Countries with @UI.LineItem: [
  { Value: code, Label: '{i18n>countryCodeLabel}' },
  { Value: name, Label: '{i18n>countryNameLabel}' }
];

annotate CatalogService.Categories with @(
  UI.HeaderInfo: { TypeName: '{i18n>categoryLabel}', TypeNamePlural: '{i18n>categoriesLabel}', Title: { Value: name } },
  UI.SelectionFields: [name],
  UI.LineItem: [
    { Value: categoryId, Label: '{i18n>categoryCodeLabel}' },
    { Value: name, Label: '{i18n>categoryNameLabel}' }
  ]
);
annotate CatalogService.Categories with {
  ID         @UI.Hidden;
  categoryId @title: '{i18n>categoryCodeLabel}';
  name       @(
    title: '{i18n>categoryNameLabel}',
    Common.ValueList: {
      CollectionPath: 'Categories',
      Parameters: [
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'categoryId' },
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: name, ValueListProperty: 'name' }
      ]
    }
  );
};

annotate CatalogService.Languages with @UI.LineItem: [
  { Value: name, Label: '{i18n>languageLabel}' }
];

annotate CatalogService.AvailabilityStatuses with @UI.LineItem: [
  { Value: name, Label: '{i18n>availabilityLabel}' }
];

annotate CatalogService.Publishers with @(
  UI.HeaderInfo: { TypeName: '{i18n>publisherLabel}', TypeNamePlural: '{i18n>publishersLabel}', Title: { Value: name } },
  UI.SelectionFields: [name],
  UI.LineItem: [
    { Value: publisherId, Label: '{i18n>publisherCodeLabel}' },
    { Value: name, Label: '{i18n>publisherNameLabel}' },
    { Value: countryCode, Label: '{i18n>countryCodeLabel}' },
    { Value: website, Label: '{i18n>websiteLabel}' }
  ]
);
annotate CatalogService.Publishers with {
  ID          @UI.Hidden;
  publisherId @title: '{i18n>publisherCodeLabel}';
  name        @title: '{i18n>publisherNameLabel}';
  countryCode @title: '{i18n>countryCodeLabel}';
  website     @title: '{i18n>websiteLabel}';
};

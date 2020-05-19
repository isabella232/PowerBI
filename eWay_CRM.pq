// This file contains your Data Connector logic
[Version = "1.3.1"]
section eWayCRM;

[DataSource.Kind="eWayCRM", Publish="eWayCRM.Publish"]
shared eWayCRM.Contents = Value.ReplaceType(eWayCRM_Implementation, eWayCRM_Type);

eWayCRM.Data = (FolderName as text, optional IncludeRelations as logical) =>
    let
        Credential = Extension.CurrentCredential(),
        UrlParts = Text.Split(Credential[Username], "@"),
        Username = UrlParts{0},
        WebServiceUrl = "https://" & UrlParts{1},
        Password = Credential[Password],
        LoginUrl = WebServiceUrl & "/API.svc/Login",
        IncludeRelations = if (IncludeRelations = null) then false else IncludeRelations,
        IncludeRelationsParameter = if (IncludeRelations = true) then "true" else "false",
        SessionBody = "{ ""userName"": """ & Username & """, ""passwordHash"": """ & Password & """, ""appVersion"": ""PowerBI_Connector_131"", ""clientMachineIdentifier"": ""B39B35C4-70B3-4495-A1D4-258F3E557C19"" }",
        SessionResult = Json.Document(Web.Contents(LoginUrl,
            [
                Headers = [#"Content-Type"="application/json"],
                Content = Text.ToBinary(SessionBody),
                IsRetry = true
            ]
        )),
        SessionId = SessionResult[SessionId],
        DataUrl = WebServiceUrl & "/API.svc/Get" & FolderName,
        DataBody = "{ ""sessionId"": """ & SessionId & """, ""includeRelations"": " & IncludeRelationsParameter & ", ""includeForeignKeys"": true }",
        DataResult = Json.Document(Web.Contents(DataUrl,
            [
                Headers = [#"Content-Type"="application/json"],
                Content = Text.ToBinary(DataBody),
                Timeout=#duration(0, 0, 5, 0)
            ]
        )),
        AdditionalFieldsUrl = WebServiceUrl & "/API.svc/SearchAdditionalFields",
        AdditionalFieldsBody = "{ ""sessionId"": """ & SessionId & """,	""transmitObject"": { ""ObjectTypeFolderName"": """ & FolderName & """ } }",
        AdditionalFields = Json.Document(Web.Contents(AdditionalFieldsUrl,
            [
                Headers = [#"Content-Type"="application/json"],
                Content = Text.ToBinary(AdditionalFieldsBody),
                Timeout=#duration(0, 0, 1, 0)
            ]
        )),
        AdditionalFieldsJsonData = AdditionalFields[Data],
        AdditionalFieldsJsonDataTable = Table.FromList(AdditionalFieldsJsonData, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        AdditionalFieldsTable = FilterAdditionalFields(ExpandRows(AdditionalFieldsJsonDataTable, GetSchemaForEntity("AdditionalFields"))),
        JsonData = DataResult[Data],
        JsonDataTable = Table.FromList(JsonData, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        Table = ExpandRows(JsonDataTable, InsertStandardFieldsToSchema(GetSchemaForEntity(FolderName)), AdditionalFieldsTable)
    in
        Table;

eWayCRM_Type = type function (
    optional IncludeRelations as (type logical meta [
        Documentation.FieldCaption = "Include Relations",
        Documentation.FieldDescription = "Load also relations between items."
    ]))
    as table;

eWayCRM_Implementation = (optional IncludeRelations as logical) =>
    let
        Objects = #table(
            { "Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf" }, {
            { "Bookkeeping", "Carts", eWayCRM.Data("Carts", IncludeRelations), "Table", "Table", true},
            { "Calendar", "Calendars", eWayCRM.Data("Calendars", IncludeRelations), "Table", "Table", true},
            { "Categories", "Groups", eWayCRM.Data("Groups", IncludeRelations), "Table", "Table", true},
            { "Custom Fields", "AdditionalFields", eWayCRM.Data("AdditionalFields", IncludeRelations), "Table", "Table", true},
            { "Companies", "Companies", eWayCRM.Data("Companies", IncludeRelations), "Table", "Table", true},
            { "Contacts", "Contacts", eWayCRM.Data("Contacts", IncludeRelations), "Table", "Table", true},
            { "Deals", "Leads", eWayCRM.Data("Leads", IncludeRelations), "Table", "Table", true},
            { "Discount Lists", "SalePrices", eWayCRM.Data("SalePrices", IncludeRelations), "Table", "Table", true},
            { "Documents", "Documents", eWayCRM.Data("Documents", IncludeRelations), "Table", "Table", true},
            { "Drop Down Menu", "EnumTypes", eWayCRM.Data("EnumTypes", IncludeRelations), "Table", "Table", true},
            { "Drop Down Menu Values", "EnumValues", eWayCRM.Data("EnumValues", IncludeRelations), "Table", "Table", true},
            { "Emails", "Emails", eWayCRM.Data("Emails", IncludeRelations), "Table", "Table", true},
            { "Exchange Rates", "CurrencyExchangeRates", eWayCRM.Data("CurrencyExchangeRates", IncludeRelations), "Table", "Table", true},
            { "Features", "Features", eWayCRM.Data("Features", IncludeRelations), "Table", "Table", true},
            { "Flows", "Flows", eWayCRM.Data("Flows", IncludeRelations), "Table", "Table", true},
            { "Global Settings", "GlobalSettings", eWayCRM.Data("GlobalSettings", IncludeRelations), "Table", "Table", true},
            { "Journal", "Journals", eWayCRM.Data("Journals", IncludeRelations), "Table", "Table", true},
            { "Marketing", "MarketingCampaigns", eWayCRM.Data("MarketingCampaigns", IncludeRelations), "Table", "Table", true},
            { "Marketing List", "MarketingListsRecords", eWayCRM.Data("MarketingListsRecords", IncludeRelations), "Table", "Table", true},
            { "Multi Select Drop Down Relations", "EnumValuesRelations", eWayCRM.Data("EnumValuesRelations", IncludeRelations), "Table", "Table", true},
            { "Products", "Goods", eWayCRM.Data("Goods", IncludeRelations), "Table", "Table", true},
            { "Products in Bookkeeping Record", "GoodsInCart", eWayCRM.Data("GoodsInCart", IncludeRelations), "Table", "Table", true},
            { "Projects", "Projects", eWayCRM.Data("Projects", IncludeRelations), "Table", "Table", true},
            { "Recurrence Patterns", "RecurrencePatterns", eWayCRM.Data("RecurrencePatterns", IncludeRelations), "Table", "Table", true},
            { "Tasks", "Tasks", eWayCRM.Data("Tasks", IncludeRelations), "Table", "Table", true},
            { "Time Sheets", "WorkReports", eWayCRM.Data("WorkReports", IncludeRelations), "Table", "Table", true},
            { "Workflow Diagrams", "WorkflowModels", eWayCRM.Data("WorkflowModels", IncludeRelations), "Table", "Table", true},
            { "Workflow History", "WorkflowHistoryRecords", eWayCRM.Data("WorkflowHistoryRecords", IncludeRelations), "Table", "Table", true},
            { "Users", "Users", eWayCRM.Data("Users", IncludeRelations), "Table", "Table", true},
            { "User Settings", "UserSettings", eWayCRM.Data("UserSettings", IncludeRelations), "Table", "Table", true}
            }),
        NavTable = Table.ToNavigationTable(Objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable;

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

// Data Source Kind description
eWayCRM = [
    TestConnection = (dataSourcePath) => { "eWayCRM.Contents" },
    Authentication = [
        UsernamePassword = [
            UsernameLabel = Extension.LoadString("UsernameLabel")
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

EnforceSchema.Strict = 1;               // Add any missing columns, remove extra columns, set table type
EnforceSchema.IgnoreExtraColumns = 2;   // Add missing columns, do not remove extra columns
EnforceSchema.IgnoreMissingColumns = 3; // Do not add or remove columns

SchemaTransformTable = (table as table, schema as table, optional enforceSchema as number) as table =>
    let
        // Default to EnforceSchema.Strict
        _enforceSchema = if (enforceSchema <> null) then enforceSchema else EnforceSchema.Strict,

        // Applies type transforms to a given table
        EnforceTypes = (table as table, schema as table) as table =>
            let
                map = (t) => if Type.Is(t, type list) or Type.Is(t, type record) or t = type any then null else t,
                mapped = Table.TransformColumns(schema, {"Type", map}),
                omitted = Table.SelectRows(mapped, each [Type] <> null),
                existingColumns = Table.ColumnNames(table),
                removeMissing = Table.SelectRows(omitted, each List.Contains(existingColumns, [Name])),
                primativeTransforms = Table.ToRows(removeMissing),
                changedPrimatives = Table.TransformColumnTypes(table, primativeTransforms)
            in
                changedPrimatives,

        // Returns the table type for a given schema
        SchemaToTableType = (schema as table) as type =>
            let
                toList = List.Transform(schema[Type], (t) => [Type=t, Optional=false]),
                toRecord = Record.FromList(toList, schema[Name]),
                toType = Type.ForRecord(toRecord, false)
            in
                type table (toType),

        // Determine if we have extra/missing columns.
        // The enforceSchema parameter determines what we do about them.
        schemaNames = schema[Name],
        foundNames = Table.ColumnNames(table),
        addNames = List.RemoveItems(schemaNames, foundNames),
        extraNames = List.RemoveItems(foundNames, schemaNames),
        tmp = Text.NewGuid(),
        added = Table.AddColumn(table, tmp, each []),
        expanded = Table.ExpandRecordColumn(added, tmp, addNames),
        result = if List.IsEmpty(addNames) then table else expanded,
        fullList =
            if (_enforceSchema = EnforceSchema.Strict) then
                schemaNames
            else if (_enforceSchema = EnforceSchema.IgnoreMissingColumns) then
                foundNames
            else
                schemaNames & extraNames,

        // Select the final list of columns.
        // These will be ordered according to the schema table.
        reordered = Table.SelectColumns(result, fullList, MissingField.Ignore),
        enforcedTypes = EnforceTypes(reordered, schema),
        withType = if (_enforceSchema = EnforceSchema.Strict) then Value.ReplaceType(enforcedTypes, SchemaToTableType(schema)) else enforcedTypes
    in
        withType;

ExpandRows = (table as table, schema as table, optional additionalFields as table) as table =>
    let
        schemaNames = schema[Name],
        expanded = Table.ExpandRecordColumn(table, "Column1", schemaNames),
        expandedWithAdditionalFields = if (additionalFields = null) then expanded else Table.ExpandRecordColumn(expanded, "AdditionalFields", GetAdditionalFieldNames(additionalFields)),
        schemaWithAdditionalFields = if (additionalFields = null) then schema else InsertAdditionalFieldsToSchema(additionalFields, schema),
        data = SchemaTransformTable(expandedWithAdditionalFields, schemaWithAdditionalFields)
    in
        data;

FilterAdditionalFields = (additionalFields as table) as table =>
    let
        filtered = Table.SelectRows(additionalFields, each [Type] <> 8)
    in
        filtered;

GetAdditionalFieldNames = (additionalFields as table) as list =>
    let
        names = Table.TransformRows(additionalFields, each "af_" & Number.ToText([FieldId]))
    in
        names;

StandardFields = #table({"Name", "Type"}, {
        {"ItemGUID", type text},
        {"ItemVersion", type number},
        {"AdditionalFields", type text},
        {"FileAs", type text},
        {"CreatedByGUID", type text},
        {"ItemChanged", type datetime},
        {"ItemCreated", type datetime},
        {"ModifiedByGUID", type text},
        {"OwnerGUID", type text},
        {"Server_ItemChanged", type datetime},
        {"Server_ItemCreated", type datetime}
    });

SchemaTable = #table({"Entity", "SchemaTable"}, {
    {"AdditionalFields", #table({"Name", "Type"}, {
        {"ItemGUID", type text},
        {"AdditionalFields", type text},
        {"Name", type text},
        {"FieldId", type number},
        {"ObjectTypeFolderName", type text},
        {"Type", type number}
    })},
    {"Users", #table({"Name", "Type"}, {
        {"IsPrivate", type logical},
        {"BankAccount", type text},
        {"BirthPlace", type text},
        {"Birthdate", type datetime},
        {"BusinessPhoneNumber", type text},
        {"BusinessPhoneNumberNormalized", type text},
        {"Email1Address", type text},
        {"Email2Address", type text},
        {"FamilyStatusEn", type text},
        {"FirstName", type text},
        {"HealthInsurance", type text},
        {"HolidayLength", type number},
        {"HomeAddressCity", type text},
        {"HomeAddressCountryEn", type text},
        {"HomeAddressPOBox", type text},
        {"HomeAddressPostalCode", type text},
        {"HomeAddressState", type text},
        {"HomeAddressStreet", type text},
        {"ICQ", type text},
        {"IDCardNumber", type text},
        {"IdentificationNumber", type text},
        {"IsActive", type logical},
        {"IsHRManager", type logical},
        {"IsProjectManager", type logical},
        {"IsSystem", type logical},
        {"JobTitle", type text},
        {"LastName", type text},
        {"MSN", type text},
        {"MiddleName", type text},
        {"MobilePhoneNumber", type text},
        {"MobilePhoneNumberNormalized", type text},
        {"Note", type text},
        {"PersonalIdentificationNumber", type text},
        {"PrefixEn", type text},
        {"ProfilePicture", type binary},
        {"ProfilePictureHeight", type number},
        {"ProfilePictureWidth", type number},
        {"RemainingDaysOfHoliday", type number},
        {"SalaryDateEn", type text},
        {"Skype", type text},
        {"SuffixEn", type text},
        {"TimeAccessibility", type text},
        {"TransportMode", type text},
        {"TravelDistance", type text},
        {"Username", type text},
        {"WorkdayStartTime", type text},
        {"Users_SupervisorGuid", type text}
    })},
    {"Leads", #table({"Name", "Type"}, {
        {"ItemGUID", type text},
        {"AdditionalFields", type text},
        {"FileAs", type text},
        {"Probability", type number}
    })}
});

GetSchemaForEntity = (entity as text) as table => try SchemaTable{[Entity=entity]}[SchemaTable] otherwise error "Couldn't find entity: '" & entity &"'";

InsertAdditionalFieldsToSchema = (additionalFields as table, schema as table) as table =>
    let
        filteredSchema = Table.SelectRows(schema, each [Name] <> "AdditionalFields"),
        table = Table.InsertRows(filteredSchema, 0, Table.TransformRows(additionalFields, (row) as record => [Name = "af_" & Number.ToText(row[FieldId]), Type = GetAdditionalFieldType(row[Type])]))
    in
        table;

InsertStandardFieldsToSchema = (schema as table) as table =>
    let
        table = Table.InsertRows(schema, 0, Table.TransformRows(StandardFields, (row) as record => [Name = row[Name], Type = row[Type]]))
    in
        table;

GetAdditionalFieldType = (fieldType as number) as type =>
    let
        tableType = if (fieldType) = 2 then type number else
            if (fieldType) = 4 then type logical else
            if (fieldType) = 6 then type date
            else type text
    in
        tableType;

// Data Source UI publishing description
eWayCRM.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://www.eway-crm.com/",
    SourceImage = eWayCRM.Icons,
    SourceTypeImage = eWayCRM.Icons
];

eWayCRM.Icons = [
    Icon16 = { Extension.Contents("eWay_CRM16.png"), Extension.Contents("eWay_CRM20.png"), Extension.Contents("eWay_CRM24.png"), Extension.Contents("eWay_CRM32.png") },
    Icon32 = { Extension.Contents("eWay_CRM32.png"), Extension.Contents("eWay_CRM40.png"), Extension.Contents("eWay_CRM48.png"), Extension.Contents("eWay_CRM64.png") }
];

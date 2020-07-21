// This file contains your Data Connector logic
[Version = "1.4.3"]
section eWayCRM;

[DataSource.Kind="eWayCRM", Publish="eWayCRM.Publish"]
shared eWayCRM.Contents = Value.ReplaceType(eWayCRM_Implementation, eWayCRM_Type);

eWayCRM.Data = (FolderName as text, optional IncludeRelations as logical) =>
    let
        Credential = Extension.CurrentCredential(),
        WebServiceUrl = GetWebServiceFromToken(Credential[access_token]),
        UserName = GetUserNameFromToken(Credential[access_token]),
        ApiUrl = if (Text.StartsWith(WebServiceUrl, "http://")) then WebServiceUrl & "InsecureAPI.svc/" else WebServiceUrl & "API.svc/",
        LoginUrl = ApiUrl & "Login",
        IncludeRelations = if (IncludeRelations = null) then false else IncludeRelations,
        IncludeRelationsParameter = if (IncludeRelations = true) then "true" else "false",
        SessionBody = "{ ""userName"": """ & UserName & """, ""appVersion"": ""PowerBI_Connector_143"", ""clientMachineIdentifier"": ""B39B35C4-70B3-4495-A1D4-258F3E557C19"" }",
        SessionResult = Json.Document(Web.Contents(LoginUrl,
            [
                Headers = [#"Content-Type"="application/json"],
                Content = Text.ToBinary(SessionBody),
                IsRetry = true
            ]
        )),
        SessionId = SessionResult[SessionId],
        DataUrl = ApiUrl & "Get" & FolderName,
        DataBody = "{ ""sessionId"": """ & SessionId & """, ""includeRelations"": " & IncludeRelationsParameter & ", ""includeForeignKeys"": true, ""omitGoodsInCart"": true }",
        DataResult = Json.Document(Web.Contents(DataUrl,
            [
                Headers = [#"Content-Type"="application/json"],
                Content = Text.ToBinary(DataBody),
                Timeout=#duration(0, 0, 5, 0)
            ]
        )),
        AdditionalFieldsUrl = ApiUrl & "/SearchAdditionalFields",
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
        AdditionalFieldsTable = FilterAdditionalFields(ExpandRows(AdditionalFieldsJsonDataTable, InsertStandardFieldsToSchema(GetSchemaForEntity("AdditionalFields")), IncludeRelations)),
        JsonData = DataResult[Data],
        JsonDataTable = Table.FromList(JsonData, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        Table = ExpandRows(JsonDataTable, InsertStandardFieldsToSchema(GetSchemaForEntity(FolderName)), IncludeRelations, AdditionalFieldsTable)
    in
        Table;

Base64UrlToBase64 = (base64Url) =>
    let
        base64 = AddPaddingToBase64String(Text.Replace(Text.Replace(base64Url, "-", "+"), "_", "/"))
    in
        base64;

AddPaddingToBase64String = (base64) =>
    let
        base64 = if (Number.Mod(Text.Length(base64), 4)) <> 0 then AddPaddingToBase64String(base64 & "=") else base64
    in
        base64;

GetWebServiceFromToken = (token) =>
    let
        Json = Json.Document(Binary.FromText(Base64UrlToBase64(Text.Split(token, "."){1}), BinaryEncoding.Base64)),
        WebService = Record.Field(Json, "ws") & "/"
    in
        WebService;

GetWebServiceFromRefreshToken = (token) =>
    let
        WebService = Text.FromBinary(Binary.FromText(Base64UrlToBase64(Text.Split(token, "."){1}), BinaryEncoding.Base64))
    in
        WebService;

GetUserNameFromToken = (token) =>
    let
        Json = Json.Document(Binary.FromText(Base64UrlToBase64(Text.Split(token, "."){1}), BinaryEncoding.Base64)),
        UserName = Record.Field(Json, "username")
    in
        UserName;

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

// OAuth2 flow definition
redirectUri = "https://oauth.powerbi.com/views/oauthredirect.html";
windowWidth = 458;
windowHeight = 498;
clientId = "powerbi";
clientSecret = Text.FromBinary(Extension.Contents("client_secret"));

CreateSha256Hash = (codeVerifier) =>
    let
        Hash = Crypto.CreateHash(CryptoAlgorithm.SHA256, Text.ToBinary(codeVerifier)),
        Base64Text = Binary.ToText(Hash, BinaryEncoding.Base64),
        Base64TextTrimmed = Text.TrimEnd(Base64Text, "="),
        Base64Url = Text.Replace(Text.Replace(Base64TextTrimmed, "+", "-"), "/", "_")
    in
        Base64Url;

StartLogin = (resourceUrl, state, display) =>
    let
        CodeVerifier = Text.NewGuid() & Text.NewGuid(),
        AuthorizeUrl = "https://login.eway-crm.com/?" & Uri.BuildQueryString([
            client_id = clientId,
            scope = "api offline_access",
            state = state,
            redirect_uri = redirectUri,
            code_challenge = CreateSha256Hash(CodeVerifier),
            code_challenge_method = "S256",
            response_type = "code"])
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirectUri,
            WindowHeight = windowHeight,
            WindowWidth = windowWidth,
            Context = CodeVerifier
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        Parts = Uri.Parts(callbackUri)[Query]
    in
        TokenMethod(Parts[code], "authorization_code", Parts[ws_url], context);

TokenMethod = (code, grant_type, ws_url, optional verifier) =>
    let
        CodeVerifier = if (verifier <> null) then [code_verifier = verifier] else [],
        Response = Web.Contents(ws_url & "/auth/connect/token", [
            Content = Text.ToBinary(Uri.BuildQueryString(CodeVerifier & [
                client_id = clientId,
                client_secret = clientSecret,
                code = code,
                refresh_token = code,
                redirect_uri = redirectUri,
                grant_type = grant_type])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"]]),
        Parts = Json.Document(Response)
    in
        Parts;

Refresh = (resourceUrl, refresh_token) =>
    let
        WebService = GetWebServiceFromRefreshToken(refresh_token),
        Parts = TokenMethod(refresh_token, "refresh_token", WebService)
    in
        Parts;

// Data Source Kind description
eWayCRM = [
    TestConnection = (dataSourcePath) => { "eWayCRM.Contents" },
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh,
            Label = Extension.LoadString("AuthenticationLabel")
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

ExpandRows = (table as table, schema as table, includeRelations as logical, optional additionalFields as table) as table =>
    let
        schemaNames = schema[Name],
        expanded = if (Table.HasColumns(table, { "Column1" })) then Table.ExpandRecordColumn(table, "Column1", schemaNames) else table,
        expandedWithRelations = if (includeRelations and Table.HasColumns(expanded, { "Relations" })) then Table.ExpandListColumn(expanded, "Relations") else expanded,
        expandedWithRelationRecords = if (includeRelations and Table.HasColumns(expandedWithRelations, { "Relations" })) then Table.ExpandRecordColumn(expandedWithRelations, "Relations", RelationsSchema[OriginalName], RelationsSchema[Name]) else expandedWithRelations,
        schemaWithRelations = if (includeRelations and Table.HasColumns(expandedWithRelations, { "Relations" })) then InsertRelationFieldsToSchema(schema) else schema,
        expandedWithAdditionalFields = if (additionalFields = null or not Table.HasColumns(expandedWithRelations, { "AdditionalFields" })) then expandedWithRelationRecords else Table.ExpandRecordColumn(expandedWithRelationRecords, "AdditionalFields", GetAdditionalFieldNames(additionalFields)),
        schemaWithAdditionalFields = if (additionalFields = null or not Table.HasColumns(expandedWithRelations, { "AdditionalFields" })) then schemaWithRelations else InsertAdditionalFieldsToSchema(additionalFields, schemaWithRelations),
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

RelationsSchema = #table({"OriginalName", "Type", "Name"}, {
        {"DifferDirection", type logical, "Relations_DifferDirection"},
        {"ForeignFolderName", type text, "Relations_ForeignFolderName"},
        {"ForeignItemGUID", type text, "Relations_ForeignItemGUID"},
        {"ItemGUID", type text, "Relations_ItemGUID"},
        {"OwnerGUID", type text, "Relations_OwnerGUID"},
        {"RelationDataGUID", type text, "Relations_RelationDataGUID"},
        {"RelationType", type text, "Relation_sRelationType"}
    });

StandardFields = #table({"Name", "Type"}, {
        {"ItemGUID", type text},
        {"ItemVersion", type number},
        {"AdditionalFields", type text},
        {"Relations", type text},
        {"FileAs", type text},
        {"CreatedByGUID", type text},
        {"ItemChanged", type datetime},
        {"ItemCreated", type datetime},
        {"ModifiedByGUID", type text},
        {"OwnerGUID", type text},
        {"Server_ItemChanged", type datetime},
        {"Server_ItemCreated", type datetime},
        {"IsPrivate", type logical}
    });

SchemaTable = #table({"Entity", "SchemaTable"}, {
    {"AdditionalFields", #table({"Name", "Type"}, {
        {"AssociatedEnumTypeGuid", type text},
        {"CategoryEn", type text},
        {"Comment", type text},
        {"Data", type text},
        {"Data_EditMask", type text},
        {"Data_FormatType", type text},
        {"Data_IsDateTime", type logical},
        {"Data_LinkType", type text},
        {"Data_MemoBoxLines", type number},
        {"Data_RelatedFolderName", type text},
        {"Data_SummaryType", type text},
        {"FieldId", type number},
        {"IsInGeneralSection", type logical},
        {"Name", type text},
        {"ObjectTypeFolderName", type text},
        {"ObjectTypeId", type number},
        {"Rank", type number},
        {"Type", type number}
    })},
    {"Calendars", #table({"Name", "Type"}, {
        {"BusyStatus", type number},
        {"BusyStatusEn", type text},
        {"EndDate", type datetime},
        {"IsAllDayEvent", type logical},
        {"Location", type text},
        {"Note", type text},
        {"Sensitivity", type number},
        {"StartDate", type datetime},
        {"Companies_TaskParentGuid", type text},
        {"Contacts_TaskParentGuid", type text},
        {"Leads_TaskParentGuid", type text},
        {"Marketing_TaskParentGuid", type text},
        {"Projects_TaskParentGuid", type text}
    })},
    {"Carts", #table({"Name", "Type"}, {
        {"AccountingCaseDate", type datetime},
        {"CurrencyEn", type text},
        {"EffectiveFrom", type datetime},
        {"ForPayment", type number},
        {"ForPaymentDefaultCurrency", type number},
        {"ForPaymentParentCurrency", type number},
        {"GoodsInCartCount", type number},
        {"Id", type number},
        {"IsActive", type logical},
        {"Note", type text},
        {"Paid", type number},
        {"PaidChanged", type datetime},
        {"PaidDefaultCurrency", type number},
        {"PaidParentCurrency", type number},
        {"PaymentDate", type datetime},
        {"PrevStateEn", type text},
        {"PriceTotal", type number},
        {"PriceTotalChanged", type datetime},
        {"PriceTotalDefaultCurrency", type number},
        {"PriceTotalExcludingVat", type number},
        {"PriceTotalExcludingVatDefaultCurrency", type number},
        {"PriceTotalExcludingVatParentCurrency", type number},
        {"PriceTotalParentCurrency", type number},
        {"Profit", type number},
        {"ProfitChanged", type datetime},
        {"ProfitDefaultCurrency", type number},
        {"ProfitParentCurrency", type number},
        {"PurchaseExpenses", type number},
        {"PurchaseExpensesChanged", type datetime},
        {"PurchaseExpensesDefaultCurrency", type number},
        {"PurchaseExpensesParentCurrency", type number},
        {"StateEn", type text},
        {"TaxableSupplyDate", type datetime},
        {"TypeEn", type text},
        {"ValidUntil", type datetime},
        {"Vat", type number},
        {"VatDefaultCurrency", type number},
        {"VatParentCurrency", type number},
        {"Companies_CustomerGuid", type text},
        {"Contacts_ContactPersonGuid", type text},
        {"Leads_CartGuid", type text},
        {"Projects_CartGuid", type text}
    })},
    {"Companies", #table({"Name", "Type"}, {
        {"AccountNumber", type text},
        {"AdditionalDiscount", type number},
        {"Address1City", type text},
        {"Address1CountryEn", type text},
        {"Address1POBox", type text},
        {"Address1PostalCode", type text},
        {"Address1State", type text},
        {"Address1Street", type text},
        {"Address2City", type text},
        {"Address2CountryEn", type text},
        {"Address2POBox", type text},
        {"Address2PostalCode", type text},
        {"Address2State", type text},
        {"Address2Street", type text},
        {"Address3City", type text},
        {"Address3CountryEn", type text},
        {"Address3POBox", type text},
        {"Address3PostalCode", type text},
        {"Address3State", type text},
        {"Address3Street", type text},
        {"CompanyName", type text},
        {"Competitor", type logical},
        {"Department", type text},
        {"Email", type text},
        {"EmailOptOut", type logical},
        {"EmployeesCount", type number},
        {"Fax", type text},
        {"FirstContactEn", type text},
        {"ICQ", type text},
        {"ID", type number},
        {"IdentificationNumber", type text},
        {"ImportanceEn", type text},
        {"LastActivity", type datetime},
        {"LineOfBusiness", type text},
        {"MSN", type text},
        {"MailingListOther", type text},
        {"Mobile", type text},
        {"MobileNormalized", type text},
        {"NextStep", type datetime},
        {"Note", type text},
        {"NotificationBy", type text},
        {"NotificationByEmail", type logical},
        {"Phone", type text},
        {"PhoneNormalized", type text},
        {"Purchaser", type logical},
        {"Reversal", type number},
        {"SalePriceGuid", type text},
        {"Skype", type text},
        {"Suppliers", type number},
        {"TypeEn", type text},
        {"VATNumber", type text},
        {"WebPage", type text}
    })},
    {"Contacts", #table({"Name", "Type"}, {
        {"BusinessAddressCity", type text},
        {"BusinessAddressCountryEn", type text},
        {"BusinessAddressPOBox", type text},
        {"BusinessAddressPostalCode", type text},
        {"BusinessAddressState", type text},
        {"BusinessAddressStreet", type text},
        {"Company", type text},
        {"Department", type text},
        {"DoNotSendNewsletter", type logical},
        {"Email1Address", type text},
        {"Email2Address", type text},
        {"Email3Address", type text},
        {"FirstName", type text},
        {"HomeAddressCity", type text},
        {"HomeAddressCountryEn", type text},
        {"HomeAddressPOBox", type text},
        {"HomeAddressPostalCode", type text},
        {"HomeAddressState", type text},
        {"HomeAddressStreet", type text},
        {"ICQ", type text},
        {"ImportanceEn", type text},
        {"LastActivity", type datetime},
        {"LastName", type text},
        {"MSN", type text},
        {"MiddleName", type text},
        {"NextStep", type datetime},
        {"Note", type text},
        {"OtherAddressCity", type text},
        {"OtherAddressCountryEn", type text},
        {"OtherAddressPOBox", type text},
        {"OtherAddressPostalCode", type text},
        {"OtherAddressState", type text},
        {"OtherAddressStreet", type text},
        {"PrefixEn", type text},
        {"ProfilePicture", type binary},
        {"ProfilePictureHeight", type number},
        {"ProfilePictureWidth", type number},
        {"Skype", type text},
        {"SuffixEn", type text},
        {"TelephoneNumber1", type text},
        {"TelephoneNumber1Normalized", type text},
        {"TelephoneNumber2", type text},
        {"TelephoneNumber2Normalized", type text},
        {"TelephoneNumber3", type text},
        {"TelephoneNumber3Normalized", type text},
        {"TelephoneNumber4", type text},
        {"TelephoneNumber4Normalized", type text},
        {"TelephoneNumber5", type text},
        {"TelephoneNumber5Normalized", type text},
        {"TelephoneNumber6", type text},
        {"TelephoneNumber6Normalized", type text},
        {"Title", type text},
        {"TypeEn", type text},
        {"WebPage", type text},
        {"Companies_CompanyGuid", type text}
    })},
    {"CurrencyExchangeRates", #table({"Name", "Type"}, {
        {"From", type datetime},
        {"InputCurrencyEn", type text},
        {"IsValid", type logical},
        {"OutputCurrencyEn", type text},
        {"Rate", type number},
        {"To", type datetime}
    })},
    {"Documents", #table({"Name", "Type"}, {
        {"CreationTime", type datetime},
        {"DocName", type text},
        {"DocSize", type number},
        {"Extension", type text},
        {"ImportanceEn", type text},
        {"IsGdprRelevant", type logical},
        {"LastWriteTime", type datetime},
        {"Note", type text},
        {"PrevStateEn", type text},
        {"Preview", type binary},
        {"PreviewHeight", type number},
        {"PreviewWidth", type number},
        {"StateEn", type text},
        {"TypeEn", type text},
        {"Companies_CompanyGuid", type text},
        {"Contacts_ContactGuid", type text},
        {"Leads_SuperiorItemGuid", type text},
        {"Marketing_SuperiorItemGuid", type text},
        {"Projects_SuperiorItemGuid", type text}
    })},
    {"Emails", #table({"Name", "Type"}, {
        {"AttachmentsCount", type number},
        {"Cc", type text},
        {"Checksum", type text},
        {"ConversationIndex", type text},
        {"EmailFileExtension", type text},
        {"Hash", type text},
        {"ImportanceEn", type text},
        {"IsGdprRelevant", type logical},
        {"MessageId", type text},
        {"Note", type text},
        {"ReceivedTime", type datetime},
        {"SenderEmailAddress", type text},
        {"SentMailGUID", type text},
        {"SentOn", type datetime},
        {"Subject", type text},
        {"To", type text},
        {"Leads_OutlookProjectGuid", type text},
        {"Marketing_OutlookProjectGuid", type text},
        {"Projects_OutlookProjectGuid", type text},
        {"Tasks_TaskOriginGuid", type text}
    })},
    {"EnumTypes", #table({"Name", "Type"}, {
        {"AllowEditLastActivity", type logical},
        {"AllowEditVisibility", type logical},
        {"AssociatedAdditionalFieldId", type number},
        {"EnumName", type text},
        {"IsAdditionalField", type logical},
        {"IsSystem", type logical},
        {"NameCs", type text},
        {"NameDe", type text},
        {"NameEn", type text},
        {"NameNo", type text},
        {"NameRu", type text},
        {"NameSk", type text},
        {"RequireDefaultValue", type logical}
    })},
    {"EnumValues", #table({"Name", "Type"}, {
        {"Cs", type text},
        {"De", type text},
        {"En", type text},
        {"EnumType", type text},
        {"EnumTypeName", type text},
        {"IncludeInLastActivityCalculation", type logical},
        {"IsDefault", type logical},
        {"IsSystem", type logical},
        {"IsVisible", type logical},
        {"No", type text},
        {"Rank", type number},
        {"Ru", type text},
        {"Sk", type text}
    })},
    {"EnumValuesRelations", #table({"Name", "Type"}, {
        {"EnumValueGuid", type text},
        {"FieldName", type text},
        {"ObjectTypeFolderName", type text},
        {"ObjectTypeId", type number},
        {"RelatedItemGuid", type text}
    })},
    {"Features", #table({"Name", "Type"}, {
        {"Active", type logical}
    })},
    {"Flows", #table({"Name", "Type"}, {
        {"ActionItemGuid", type text},
        {"FieldsLockedByAction", type text},
        {"ModelGuid", type text},
        {"NonEmptyFieldsPrecondition", type text},
        {"PerformsAreEqualAction", type text},
        {"PerformsCheckRelationPresenceAction", type text},
        {"PerformsCreateRelationAction", type text},
        {"PerformsCreateTaskAction", type text},
        {"PerformsLockItemAction", type text},
        {"PerformsSendEmailAction", type text},
        {"PerformsSetFieldValueAction", type text},
        {"PerformsSetOwnerAction", type text},
        {"PerformsWriteJournalAction", type text},
        {"PrecedentEn", type text},
        {"Roundtrip", type logical},
        {"SetOwnerActionMessage", type text},
        {"SuccedentEn", type text},
        {"WriteJournalActionImportnceEn", type text},
        {"WriteJournalActionMessage", type text},
        {"WriteJournalActionTitle", type text},
        {"WriteJournalActionTypeEn", type text}
    })},
    {"GlobalSettings", #table({"Name", "Type"}, {
        {"Name", type text},
        {"Value", type text}
    })},
    {"Goods", #table({"Name", "Type"}, {
        {"Code", type text},
        {"Description", type text},
        {"InventoryQuantity", type number},
        {"IsPriceSum", type logical},
        {"Note", type text},
        {"Picture", type binary},
        {"PictureHeight", type number},
        {"PictureWidth", type number},
        {"PriceListGroupGuid", type text},
        {"PurchaseCurrencyEn", type text},
        {"PurchasePrice", type number},
        {"PurchasePriceChanged", type datetime},
        {"PurchasePriceDefaultCurrency", type number},
        {"SaleCurrencyEn", type text},
        {"SalePrice", type number},
        {"SalePriceChanged", type datetime},
        {"SalePriceDefaultCurrency", type number},
        {"Structure", type text},
        {"TypeEn", type text},
        {"UnitEn", type text},
        {"VatIncluded", type logical},
        {"VatRate", type number},
        {"Goods_SuperiorGoodGuid", type text}
    })},
    {"GoodsInCart", #table({"Name", "Type"}, {
        {"ChildItemsCount", type number},
        {"Code", type text},
        {"Description", type text},
        {"Discount", type number},
        {"HierarchyInSet", type text},
        {"IncludeInCartPrice", type logical},
        {"IsFromSet", type logical},
        {"IsPriceSum", type logical},
        {"JoinedToGuid", type text},
        {"ListPrice", type number},
        {"ListPriceChanged", type datetime},
        {"ListPriceCustomized", type logical},
        {"ListPriceDefaultCurrency", type number},
        {"ListPriceParentCurrency", type number},
        {"Note", type text},
        {"ParentGuid", type text},
        {"Picture", type binary},
        {"PictureHeight", type number},
        {"PictureWidth", type number},
        {"PriceTotal", type number},
        {"PriceTotalChanged", type datetime},
        {"PriceTotalDefaultCurrency", type number},
        {"PriceTotalExcludingVat", type number},
        {"PriceTotalExcludingVatDefaultCurrency", type number},
        {"PriceTotalExcludingVatParentCurrency", type number},
        {"PriceTotalParentCurrency", type number},
        {"PurchaseCurrencyEn", type text},
        {"PurchasePrice", type number},
        {"PurchasePriceChanged", type datetime},
        {"PurchasePriceDefaultCurrency", type number},
        {"PurchasePriceParentCurrency", type number},
        {"PurchasePriceTotal", type number},
        {"PurchasePriceTotalChanged", type datetime},
        {"PurchasePriceTotalDefaultCurrency", type number},
        {"PurchasePriceTotalParentCurrency", type number},
        {"Quantity", type number},
        {"Rank", type number},
        {"SaleCurrencyEn", type text},
        {"SalePrice", type number},
        {"SalePriceChanged", type datetime},
        {"SalePriceDefaultCurrency", type number},
        {"SalePriceExcludingVat", type number},
        {"SalePriceExcludingVatDefaultCurrency", type number},
        {"SalePriceExcludingVatParentCurrency", type number},
        {"SalePriceParentCurrency", type number},
        {"Structure", type text},
        {"UnitEn", type text},
        {"Vat", type number},
        {"VatDefaultCurrency", type number},
        {"VatIncluded", type logical},
        {"VatParentCurrency", type number},
        {"VatRate", type number},
        {"VatTotal", type number},
        {"VatTotalDefaultCurrency", type number},
        {"VatTotalParentCurrency", type number},
        {"Carts_GoodsInCartGuid", type text},
        {"Goods_GoodsInfoGuid", type text},
        {"Leads_ProjectGuid", type text},
        {"Projects_ProjectGuid", type text}
    })},
    {"Groups", #table({"Name", "Type"}, {
        {"Description", type text},
        {"DisallowControlColumnPermissions", type logical},
        {"DisallowControlModulePermissions", type logical},
        {"DisallowControlUserAssignment", type logical},
        {"GroupName", type text},
        {"IsAdmin", type logical},
        {"IsCategory", type logical},
        {"IsOutlookCategory", type logical},
        {"IsPM", type logical},
        {"IsRole", type logical},
        {"ResponsibilityDescription", type text},
        {"System", type logical}
    })},
    {"Journals", #table({"Name", "Type"}, {
        {"CalendarEntryID", type text},
        {"Calendar_ORIGIN", type text},
        {"ChangedField", type text},
        {"EventEnd", type datetime},
        {"EventStart", type datetime},
        {"FieldValue", type text},
        {"ImportanceEn", type text},
        {"IsGdprRelevant", type logical},
        {"IsSystem", type logical},
        {"Note", type text},
        {"Phone", type text},
        {"PhoneNormalized", type text},
        {"PrevFieldValue", type text},
        {"TypeEn", type text},
        {"Companies_CompanyGuid", type text},
        {"Contacts_ContactGuid", type text},
        {"Leads_SuperiorItemGuid", type text},
        {"Marketing_MarketingGuid", type text},
        {"Marketing_SuperiorItemGuid", type text}
    })},
    {"Leads", #table({"Name", "Type"}, {
        {"City", type text},
        {"ContactPerson", type text},
        {"CountryEn", type text},
        {"CurrencyEn", type text},
        {"Customer", type text},
        {"Email", type text},
        {"EmailOptOut", type logical},
        {"EstimatedEnd", type datetime},
        {"EstimatedValue", type number},
        {"HID", type number},
        {"IsCompleted", type logical},
        {"IsLost", type logical},
        {"LastActivity", type datetime},
        {"LeadOriginEn", type text},
        {"NextStep", type datetime},
        {"Note", type text},
        {"POBox", type text},
        {"Phone", type text},
        {"PhoneNormalized", type text},
        {"PrevStateEn", type text},
        {"Price", type number},
        {"PriceChanged", type datetime},
        {"PriceDefaultCurrency", type number},
        {"Probability", type number},
        {"ReceiveDate", type datetime},
        {"State", type text},
        {"StateEn", type text},
        {"Street", type text},
        {"TypeEn", type text},
        {"Zip", type text},
        {"Companies_CustomerGuid", type text},
        {"Contacts_ContactPersonGuid", type text},
        {"Marketing_MarketingGuid", type text}
    })},
    {"MarketingCampaigns", #table({"Name", "Type"}, {
        {"Budget", type number},
        {"EmailCampaignContactListChanged", type logical},
        {"EmailCampaignEmailSent", type datetime},
        {"EmailCampaignHash", type text},
        {"EmailsDelivered", type number},
        {"EmailsMarkedAsSpam", type number},
        {"EmailsSent", type number},
        {"EmailsViewed", type number},
        {"EstimatedEnd", type datetime},
        {"EstimatedResponses", type number},
        {"EstimatedRevenues", type number},
        {"EstimatedStart", type datetime},
        {"Expenses", type number},
        {"FinalResponses", type number},
        {"FinalRevenues", type number},
        {"ID", type number},
        {"LastResponsesDownloadTime", type datetime},
        {"Note", type text},
        {"PeopleUnsubscribed", type number},
        {"PrevStateEn", type text},
        {"RealEnd", type datetime},
        {"RealStart", type datetime},
        {"ResponsesDownloadCount", type number},
        {"StateEn", type text},
        {"TargetGroup", type number},
        {"TypeEn", type text}
    })},
    {"MarketingListsRecords", #table({"Name", "Type"}, {
        {"AddressCity", type text},
        {"AddressPostalCode", type text},
        {"AddressStreet", type text},
        {"Company", type text},
        {"CompanyGuid", type text},
        {"Contact", type text},
        {"ContactGuid", type text},
        {"Email1Address", type text},
        {"FirstName", type text},
        {"FolderName", type text},
        {"LastName", type text},
        {"LeadGuid", type text},
        {"MarketingCampaignGuid", type text},
        {"Phone", type text}
    })},
    {"Projects", #table({"Name", "Type"}, {
        {"CurrencyEn", type text},
        {"EstimatedMargin", type number},
        {"EstimatedOtherExpenses", type number},
        {"EstimatedOtherExpensesChanged", type datetime},
        {"EstimatedOtherExpensesDefaultCurrency", type number},
        {"EstimatedPeopleExpenses", type number},
        {"EstimatedPeopleExpensesChanged", type datetime},
        {"EstimatedPeopleExpensesDefaultCurrency", type number},
        {"EstimatedPrice", type number},
        {"EstimatedPriceChanged", type datetime},
        {"EstimatedPriceDefaultCurrency", type number},
        {"EstimatedProfit", type number},
        {"EstimatedProfitDefaultCurrency", type number},
        {"EstimatedWorkHours", type number},
        {"HID", type number},
        {"InvoiceIssueDate", type datetime},
        {"InvoicePaymentDate", type datetime},
        {"IsCompleted", type logical},
        {"IsLost", type logical},
        {"LastActivity", type datetime},
        {"LicensePrice", type number},
        {"LicensePriceChanged", type datetime},
        {"LicensePriceDefaultCurrency", type number},
        {"LicensesCount", type number},
        {"Margin", type number},
        {"NextStep", type datetime},
        {"Note", type text},
        {"OtherExpenses", type number},
        {"OtherExpensesChanged", type datetime},
        {"OtherExpensesDefaultCurrency", type number},
        {"PaymentMaturity", type number},
        {"PaymentTypeEn", type text},
        {"PeopleExpenses", type number},
        {"PeopleExpensesChanged", type datetime},
        {"PeopleExpensesDefaultCurrency", type number},
        {"PrevStateEn", type text},
        {"Price", type number},
        {"PriceChanged", type datetime},
        {"PriceDefaultCurrency", type number},
        {"Profit", type number},
        {"ProfitDefaultCurrency", type number},
        {"ProjectEnd", type datetime},
        {"ProjectName", type text},
        {"ProjectOriginEn", type text},
        {"ProjectRealEnd", type datetime},
        {"ProjectStart", type datetime},
        {"ShowInCaplan", type logical},
        {"StateEn", type text},
        {"TotalWorkHours", type number},
        {"TypeEn", type text},
        {"Companies_CustomerGuid", type text},
        {"Contacts_ContactPersonGuid", type text},
        {"Leads_Project_OriginGuid", type text},
        {"Projects_SuperiorProjectGuid", type text},
        {"Users_SupervisorGuid", type text}
    })},
    {"RecurrencePatterns", #table({"Name", "Type"}, {
        {"DayOfMonth", type number},
        {"DayOfWeekMask", type number},
        {"EndKind", type number},
        {"Instance", type number},
        {"Interval", type number},
        {"MonthOfYear", type number},
        {"NoEndDate", type logical},
        {"Occurrences", type number},
        {"PatternEndDate", type datetime},
        {"PatternStartDate", type datetime},
        {"RecurrenceType", type number},
        {"Regenerate", type logical},
        {"TaskGuid", type text}
    })},
    {"SalePrices", #table({"Name", "Type"}, {
        {"Discount", type number},
        {"Note", type text}
    })},
    {"Tasks", #table({"Name", "Type"}, {
        {"ActualWorkHours", type number},
        {"Body", type text},
        {"CompletedDate", type datetime},
        {"DueDate", type datetime},
        {"EstimatedWorkHours", type number},
        {"ImportanceEn", type text},
        {"IsCompleted", type logical},
        {"IsReminderSet", type logical},
        {"IsTeamTask", type logical},
        {"Level", type number},
        {"PercentCompleteDecimal", type number},
        {"PrevStateEn", type text},
        {"RTFBody", type text},
        {"ReminderDate", type datetime},
        {"StartDate", type datetime},
        {"StateEn", type text},
        {"Subject", type text},
        {"TypeEn", type text},
        {"Companies_CompanyGuid", type text},
        {"Contacts_ContactGuid", type text},
        {"Leads_TaskParentGuid", type text},
        {"Leads_TopLevelProjectGuid", type text},
        {"Marketing_TaskParentGuid", type text},
        {"Marketing_TopLevelProjectGuid", type text},
        {"Projects_TaskParentGuid", type text},
        {"Projects_TopLevelProjectGuid", type text},
        {"Tasks_TaskOriginGuid", type text},
        {"Tasks_TaskParentGuid", type text},
        {"Users_TaskDelegatorGuid", type text},
        {"Users_TaskSolverGuid", type text}
    })},
    {"Users", #table({"Name", "Type"}, {
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
    {"UserSettings", #table({"Name", "Type"}, {
        {"Name", type text},
        {"Path", type text},
        {"Value", type text}
    })},
    {"WorkflowHistoryRecords", #table({"Name", "Type"}, {
        {"PrecedentEn", type text},
        {"RelatedItemFolderName", type text},
        {"RelatedItemGuid", type text},
        {"SuccedentEn", type text}
    })},
    {"WorkflowModels", #table({"Name", "Type"}, {
        {"EnumTypeGuid", type text},
        {"ParentEn", type text}
    })},
    {"WorkReports", #table({"Name", "Type"}, {
        {"CalendarEntryId", type text},
        {"CalendarOrigin", type text},
        {"CurrencyEn", type text},
        {"DayTypeEn", type text},
        {"Duration", type number},
        {"From", type datetime},
        {"ImportanceEn", type text},
        {"Month", type number},
        {"Note", type text},
        {"Overtime", type logical},
        {"PrevStateEn", type text},
        {"Rate", type number},
        {"RateAdditional", type number},
        {"RateAdditionalDefaultCurrency", type number},
        {"RateAdditionalParentCurrency", type number},
        {"RateDefaultCurrency", type number},
        {"RateParentCurrency", type number},
        {"StateEn", type text},
        {"Subject", type text},
        {"To", type datetime},
        {"TypeEn", type text},
        {"Year", type number},
        {"Leads_LeadGuid", type text},
        {"Leads_SuperiorItemGuid", type text},
        {"Projects_ProjectGuid", type text},
        {"Projects_SuperiorItemGuid", type text},
        {"Tasks_TaskGuid", type text},
        {"Users_PersonGuid", type text}
    })}
});

GetSchemaForEntity = (entity as text) as table => try SchemaTable{[Entity=entity]}[SchemaTable] otherwise error "Couldn't find entity: '" & entity &"'";

InsertAdditionalFieldsToSchema = (additionalFields as table, schema as table) as table =>
    let
        filteredSchema = Table.SelectRows(schema, each [Name] <> "AdditionalFields"),
        table = Table.InsertRows(filteredSchema, 0, Table.TransformRows(additionalFields, (row) as record => [Name = "af_" & Number.ToText(row[FieldId]), Type = GetAdditionalFieldType(row[Type])]))
    in
        table;

InsertRelationFieldsToSchema = (schema as table) as table =>
    let
        filteredSchema = Table.SelectRows(schema, each [Name] <> "Relations"),
        table = Table.InsertRows(filteredSchema, 0, Table.TransformRows(RelationsSchema, (row) as record => [Name = row[Name], Type = row[Type]]))
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
            if (fieldType) = 6 then type datetime
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

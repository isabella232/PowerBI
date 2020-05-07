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
        DataResult  = Json.Document(Web.Contents(DataUrl,
            [
                Headers = [#"Content-Type"="application/json"],
                Content = Text.ToBinary(DataBody),
                Timeout=#duration(0, 0, 5, 0)
            ]
        )),
        JsonData = DataResult[Data],
        #"Converted to Table" = Table.FromList(JsonData, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
    in
        #"Converted to Table";

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

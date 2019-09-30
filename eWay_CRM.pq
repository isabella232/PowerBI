// This file contains your Data Connector logic
section eWay_CRM;

[DataSource.Kind="eWay_CRM", Publish="eWay_CRM.Publish"]
shared eWay_CRM.Contents = Value.ReplaceType(eWay_CRM_Implementaion, eWay_CRM_Type);

eWay_CRM_Type = type function (
    WebServiceUrl as (type text meta [
        Documentation.FieldCaption = "Web Service Address",
        Documentation.FieldDescription = "Address of the eWay-CRM WebService",
        Documentation.SampleValues = { "https://eway.example.com" }
    ]),
    FolderName as (type text meta [
        Documentation.FieldCaption = "Module",
        Documentation.FieldDescription = "Name of the eWay-CRM module.",
        Documentation.AllowedValues = {
            "Bookkeeping", "Calendar", "Categories", "Companies", "Contacts", "Deals", "Discount Lists", "Documents",
            "Drop Down Menus", "Drop Down Menu Values", "Emails", "Exchange Rates", "Journal", "Marketing",
            "Marketing List", "Products", "Products in Bookkeeping Record", "Projects", "Tasks", "Time Sheets", "Users",
            "Workflow History"
        }
    ]),
    optional IncludeRelations as (type logical meta [
        Documentation.FieldCaption = "Include Relations",
        Documentation.FieldDescription = "Load also relations between items."
    ]))
    as table;

eWay_CRM_Implementaion = (WebServiceUrl as text, FolderName as text, optional IncludeRelations as logical) =>
    let
        Credential = Extension.CurrentCredential(),
        FolderName = if (FolderName = "Bookkeeping") then "Carts"
            else if (FolderName = "Deals") then "Leads"
            else if (FolderName = "Calendar") then "Calendars"
            else if (FolderName = "Categories") then "Groups"
            else if (FolderName = "Discount Lists") then "SalePrices"
            else if (FolderName = "Drop Down Menu") then "EnumTypes"
            else if (FolderName = "Drop Down Menu Values") then "EnumValues"
            else if (FolderName = "Exchange Rates") then "ExchangeRates"
            else if (FolderName = "Journal") then "Journals"
            else if (FolderName = "Marketing") then "MarketingCampaigns"
            else if (FolderName = "Marketing List") then "MarketingListsRecords"
            else if (FolderName = "Products") then "Goods"
            else if (FolderName = "Products in Bookkeeping Record") then "GoodsInCart"
            else if (FolderName = "Time Sheets") then "WorkReports"
            else if (FolderName = "Workflow History") then "WorkflowHistoryRecords" else FolderName,
        LoginUrl = WebServiceUrl & "/WcfService/Service.svc/Login",
        IncludeRelations = if (IncludeRelations = null) then false else IncludeRelations,
        IncludeRelationsParameter = if (IncludeRelations = true) then "true" else "false",
        SessionBody = "{ ""userName"": """ & Credential[Username] & """, ""passwordHash"": """ & Credential[Password] & """, ""appVersion"": ""PowerBI_Connector_10"", ""clientMachineIdentifier"": ""B39B35C4-70B3-4495-A1D4-258F3E557C19"" }",
        SessionResult = Json.Document(Web.Contents(LoginUrl,
            [
                Headers = [#"Content-Type"="application/json"],
                Content = Text.ToBinary(SessionBody)
            ]
        )),
        SessionId = SessionResult[SessionId],
        DataUrl = WebServiceUrl & "/WcfService/Service.svc/Get" & FolderName,
        DataBody = "{ ""sessionId"": """ & SessionId & """, ""includeRelations"": " & IncludeRelationsParameter & ", ""includeForeignKeys"": true }",
        DataResult  = Json.Document(Web.Contents(DataUrl,
            [
                Headers = [#"Content-Type"="application/json"],
                Content = Text.ToBinary(DataBody)
            ]
        )),
        JsonData = DataResult[Data],
        #"Converted to Table" = Table.FromList(JsonData, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
    in
        #"Converted to Table";

// Data Source Kind description
eWay_CRM = [
    Authentication = [
        UsernamePassword = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
eWay_CRM.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://www.eway-crm.com/",
    SourceImage = eWay_CRM.Icons,
    SourceTypeImage = eWay_CRM.Icons
];

eWay_CRM.Icons = [
    Icon16 = { Extension.Contents("eWay_CRM16.png"), Extension.Contents("eWay_CRM20.png"), Extension.Contents("eWay_CRM24.png"), Extension.Contents("eWay_CRM32.png") },
    Icon32 = { Extension.Contents("eWay_CRM32.png"), Extension.Contents("eWay_CRM40.png"), Extension.Contents("eWay_CRM48.png"), Extension.Contents("eWay_CRM64.png") }
];

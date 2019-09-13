// This file contains your Data Connector logic
section eWay_CRM;

[DataSource.Kind="eWay_CRM", Publish="eWay_CRM.Publish"]
shared eWay_CRM.Contents = Value.ReplaceType(eWay_CRM_Implementaion, eWay_CRM_Type);

eWay_CRM_Type = type function (
    ws_url as (type text meta [
        Documentation.FieldCaption = "Web Service Address",
        Documentation.FieldDescription = "Address of the eWay-CRM WebService",
        Documentation.SampleValues = {"https://eway.example.com"}
    ]),
    session_id as (type text meta [
        Documentation.FieldCaption = "Session ID"
    ]),
    folder_name as (type text meta [
        Documentation.FieldCaption = "Module",
        Documentation.FieldDescription = "Name of the eWay-CRM module.",
        Documentation.AllowedValues = {
            "Bookkeeping", "Calendar", "Categories", "Companies", "Contacts", "Deals", "Discount Lists", "Documents",
            "Drop Down Menus", "Drop Down Menu Values", "Emails", "Exchange Rates", "Journal", "Marketing",
            "Marketing List", "Products", "Products in Bookkeeping Record", "Projects", "Tasks", "Time Sheets", "Users",
            "Workflow History"
        }
    ]))
    as table;

eWay_CRM_Implementaion = (ws_url as text, session_id as text, folder_name as text) =>
    let
        folder_name = if (folder_name = "Bookkeeping") then "Carts"
            else if (folder_name = "Deals") then "Leads"
            else if (folder_name = "Calendar") then "Calendars"
            else if (folder_name = "Categories") then "Groups"
            else if (folder_name = "Discount Lists") then "SalePrices"
            else if (folder_name = "Drop Down Menu") then "EnumTypes"
            else if (folder_name = "Drop Down Menu Values") then "EnumValues"
            else if (folder_name = "Exchange Rates") then "ExchangeRates"
            else if (folder_name = "Journal") then "Journals"
            else if (folder_name = "Marketing") then "MarketingCampaigns"
            else if (folder_name = "Marketing List") then "MarketingListsRecords"
            else if (folder_name = "Products") then "Goods"
            else if (folder_name = "Products in Bookkeeping Record") then "GoodsInCart"
            else if (folder_name = "Time Sheets") then "WorkReports"
            else if (folder_name = "Workflow History") then "WorkflowHistoryRecords" else folder_name,
        url = ws_url & "/API.svc/Get" & folder_name,
        body = "{ ""sessionId"": """ & session_id & """ }",
        Source  = Json.Document(Web.Contents(url,
            [
                Headers = [#"Content-Type"="application/json"],
                Content=Text.ToBinary(body)
            ]
        )),
        JsonData = Source[Data],
        #"Converted to Table" = Table.FromList(JsonData, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
    in
        #"Converted to Table";

// Data Source Kind description
eWay_CRM = [
    Authentication = [
        Anonymous = []
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

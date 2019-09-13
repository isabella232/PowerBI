// This file contains your Data Connector logic
section eWay_CRM;

[DataSource.Kind="eWay_CRM", Publish="eWay_CRM.Publish"]
shared eWay_CRM.Contents = (ws_url as text, session_id as text) =>
    let
        url = ws_url & "/API.svc/GetUsers",
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

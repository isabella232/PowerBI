// This file contains your Data Connector logic
section eWay_CRM;

[DataSource.Kind="eWay_CRM", Publish="eWay_CRM.Publish"]
shared eWay_CRM.Contents = (optional message as text) =>
    let
        _message = if (message <> null) then message else "(no message)",
        a = "Hello from eWay_CRM: " & _message
    in
        a;

// Data Source Kind description
eWay_CRM = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
eWay_CRM.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = eWay_CRM.Icons,
    SourceTypeImage = eWay_CRM.Icons
];

eWay_CRM.Icons = [
    Icon16 = { Extension.Contents("eWay_CRM16.png"), Extension.Contents("eWay_CRM20.png"), Extension.Contents("eWay_CRM24.png"), Extension.Contents("eWay_CRM32.png") },
    Icon32 = { Extension.Contents("eWay_CRM32.png"), Extension.Contents("eWay_CRM40.png"), Extension.Contents("eWay_CRM48.png"), Extension.Contents("eWay_CRM64.png") }
];

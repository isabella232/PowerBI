// Use this file to write queries to test your data connector
let
    Source = eWayCRM.Contents(null),
    Users = Source{[Key="Users"]}[Data],
    Expanded = Table.ExpandRecordColumn(Users, "Column1", {"ItemGUID", "FileAs", "Email1Address", "Username"}, {"Column1.ItemGUID", "Column1.FileAs", "Column1.Email1Address", "Column1.Username"})
in
    Expanded
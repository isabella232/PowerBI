// Use this file to write queries to test your data connector
let
    Source = eWayCRM.Contents(null),
    Users = Source{[Key="Users"]}[Data]
in
    Users
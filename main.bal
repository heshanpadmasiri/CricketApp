import ballerina/http;
import ballerina/io;

type Country record {
    int id;
    string name;
};

type Ground record {|
    int id;
    string name;
    Country country;
    Location location;
|};

type Player record {|
    int id;
    string name;
    Country country;

|};
type Location [int, int];

function getFlag(record {Country country;} entity) returns string|error {
    http:Client dataClient = check new("localhost:8080");
    return dataClient->/data/flag(id = entity.country.id);
}


public function main() {
    io:println(getFlag({country: {id: 1, name: "name"}}));
}

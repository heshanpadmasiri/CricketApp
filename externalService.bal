import ballerina/http;
import ballerina/lang.runtime;

service /image on new http:Listener(8080) {
    resource function get .(int id) returns string {
        return string `http://someS3linkto_${id}`;
    }
}

service /info on new http:Listener(8081) {
    resource function get player(int id) returns Player {
        return createPlayer(id);
    }

    resource function get game(int id) returns Game {
        return createGame(id);
    }

    resource function get series(int id) returns Series {
        runtime:sleep(1000);
        return createSeries(id);
    }

    resource function get score(int id) returns Score {
        return { score: 10, wickets: 0};
    }
}

service /score on new http:Listener(8082) {
    resource function get .(int id) returns Score {
        return { score: 100, wickets: 0};
    }
}

function createPlayer(int id) returns Player {
    return {
        id: id,
        name: string `Player_${id}`,
        country: {
            id: 0,
            name: "country 1"
        }
    };
}

function createGame(int id) returns Game {
    return {
        id: id,
        weather: {
            kind: "SUNNY",
            temperature: 30
        },
        ground: {
            name: "ground 1",
            country: {
                id: 0,
                name: "country 1"
            },
            location: [0, 0],
            id: 0
        },
        team1: [
            {
                id: 1,
                name: "Player_1",
                country: {
                    id: 0,
                    name: "country 1"
                }
            },
            {
                id: 2,
                name: "Player_2",
                country: {
                    id: 0,
                    name: "country 1"
                }
            }
        ],
        team2: [
            {
                id: 1,
                name: "Player_1",
                country: {
                    id: 0,
                    name: "country 1"
                }
            },
            {
                id: 2,
                name: "Player_2",
                country: {
                    id: 0,
                    name: "country 1"
                }
            }
        ]
    };
}

function createSeries(int id) returns Series {
    string name = string `series_${id}`;
    Game[] games = from int index in 0 ..< 5
        select createGame(index);
    return {
        id: id,
        name: name,
        games: games
    };
}

import ballerina/websocket;
import ballerina/http;

// Part 1
type EntityWithId record {
    int id;
};

type Country record {
    *EntityWithId;
    string name;
};

type Ground record {|
    *EntityWithId;
    string name;
    Country country;
    Location location;
|};

type Player record {|
    *EntityWithId;
    string name;
    Country country;
|};

type Location [int, int];

type Team Player[];

type Temperature int;

type Weather record {|
    "SUNNY"|"WINDY" kind;
    Temperature temperature;
|};

type Game record {|
    *EntityWithId;
    Weather weather;
    Ground ground;
    Team team1;
    Team team2;
|};

type Series record {|
    *EntityWithId;
    string name;
    Game[] games;
|};

type ClientDataWithImage record {
    string imageUrl;
};

type CountryData record {|
    *Country;
    *ClientDataWithImage;
|};

type GroundData record {|
    *Ground;
    *ClientDataWithImage;
    CountryData country;
|};

type PlayerData record {|
    *Player;
    *ClientDataWithImage;
    CountryData country;
|};

type TeamData PlayerData[];

type GameData record {|
    *Game;
    GroundData ground;
    TeamData team1;
    TeamData team2;
|};

type SeriesData record {|
    *Series;
    GameData[] games;
|};

// End of Part 1


// Part 2

service / on new http:Listener(9009) {

    resource function get player(int id) returns PlayerData|error {
        final http:Client dataClient = checkpanic new ("localhost:8081/info");
        Player player = check dataClient->/player(id = id);
        return self.playerData(player);
    }

    resource function get game(int id) returns GameData|error {
        final http:Client dataClient = checkpanic new ("localhost:8081/info");
        Game game = check dataClient->/game(id = id);
        return self.gameData(game);
    }

    resource function get series(int id) returns SeriesData|error {
        final http:Client dataClient = checkpanic new ("localhost:8081/info");
        Series series = check dataClient->/series(id = id);
        return self.seriesData(series);
    }

    private function imageUrlOf(EntityWithId entity) returns string|error {
        final http:Client imageDataClient = checkpanic new ("localhost:8080/image");
        return imageDataClient->/(id = entity.id);
    }

    private function seriesData(Series series) returns SeriesData|error {
        GameData[] games = from Game each in series.games
            select check self.gameData(each);
        return {games, id: series.id, name: series.name};
    }

    private function gameData(Game game) returns GameData|error {
        TeamData team1 = from Player each in game.team1
            select check self.playerData(each);
        TeamData team2 = from Player each in game.team2
            select check self.playerData(each);
        GroundData ground = check self.groundData(game.ground);
        return {team1, team2, ground, weather: game.weather, id: game.id};
    }

    private function groundData(Ground ground) returns GroundData|error {
        var {id, name, country, location} = ground;
        string imageUrl = check self.imageUrlOf(ground);
        CountryData countryData = check self.countryData(country);
        return {imageUrl, id, name, country: countryData, location};
    }

    private function countryData(Country country) returns CountryData|error {
        var {id, name} = country;
        string imageUrl = check self.imageUrlOf(country);
        return {imageUrl, id, name};
    }

    private function playerData(Player player) returns PlayerData|error {
        var {id, name, country} = player;
        string imageUrl = check self.imageUrlOf(player);
        CountryData countryData = check self.countryData(country);
        return {id, name, imageUrl, country: countryData};
    }
}

service /score on new websocket:Listener(9090) {
    resource function get .() returns websocket:Service {
        return new LiveScoreService();
        // return new FastLiveScoreService();
    }
}

type Score record {
    int score;
    int wickets;
};

type ScoreRequestBase record {
    "STOP"|"NEXT" kind;
};

type NextScoreRequest record {
    "NEXT" kind;
    int gameId;
};

type StopScoreRequest record {
    "STOP" kind;
};

type ScoreRequest NextScoreRequest|StopScoreRequest;

service class LiveScoreService {
    *websocket:Service;
    final http:Client dataClient = checkpanic new ("localhost:8081/info");
    remote function onMessage(websocket:Caller caller, ScoreRequest req) returns error? {
        if (req is NextScoreRequest) {
            int gameId = req.gameId;
            Score score = check self.dataClient->/score(id = gameId);
            check caller->writeMessage(score);
        }
    }
}

// Demo3 fast worker
// FIXME: use this instead of LiveScoreService

service class FastLiveScoreService {
    *LiveScoreService;
    final http:Client dataClient = checkpanic new ("localhost:8081/info");
    final http:Client altDataClient = checkpanic new ("localhost:8082/score");
    remote function onMessage(websocket:Caller caller, ScoreRequest req) returns error? {
        if (req !is NextScoreRequest) {
            return;
        }
        int gameId = req.gameId;
        worker scoreFetcher1 returns Score|error {
            return self.dataClient->/score(id = gameId);
        }

        worker scoreFetcher2 returns Score|error {
            return self.altDataClient->/score(id = gameId);
        }
        Score score = check wait scoreFetcher1 | scoreFetcher2;
        check caller->writeMessage(score);
    }
}

-module(index).
-compile({parse_transform, shen}).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("server/include/requests.hrl").
-include_lib("server/include/settings.hrl").
-jsmacro([take/2,attach/1,join/1, discard/3]).

join(Game) ->
    ws:send(bert:encodebuf(bert:tuple(
        bert:atom('client'),
        bert:tuple(bert:atom("join_game"), Game)))).

attach(Token) ->
    ws:send(bert:encodebuf(bert:tuple(
        bert:atom('client'),
        bert:tuple(bert:atom("session_attach"), Token)))).

take(GameId,Place) ->
    ws:send(bert:encodebuf(bert:tuple(
        bert:atom('client'),
        bert:tuple(bert:atom("game_action"),GameId,bert:atom("okey_take"),[{pile,Place}])))).

discard(GameId, Color, Value) ->
    ws:send(
      bert:encodebuf(
        bert:tuple(
          bert:atom('client'),
          bert:tuple(
            bert:atom("game_action"), GameId, bert:atom("okey_discard"),
            bert:list(bert:tuple(bert:atom("tile"), bert:tuple(bert:atom("OkeyPiece"), Color, Value)))
           )
         )
       )
     ).

redraw_tiles(TilesList) ->
    wf:update(dddiscard, [#dropdown{id = drop, postback=combo, source=[drop], options = [#option{label = CVBin, value = CVBin} || {CVBin, _} <- TilesList]}]).

main() -> #dtl{file="index", bindings=[{title,<<"N2O">>},{body,body()}]}.

body() ->
    [ #panel{ id=history },
      #button{ id = attach, body = <<"Attach">>, postback = attach},
      #button{ id = join, body = <<"Join">>, postback = join},
      #dropdown{ id=ddtake, value="0", postback=combo, source=[ddtake], 
                 options = 
                     [
                      #option { label= <<"0">>, value= <<"0">> },
                      #option { label= <<"1">>, value= <<"1">> }
                     ]
               },
      #button{ id = take, body = <<"Take">>, postback = take},
      #dropdown{ id=dddiscard, value="2", postback=combo, source=[dddiscard], 
                 options = 
                     [
                      #option { label= <<"Option 1">>, value= <<"1">> },
                      #option { label= <<"Option 2">>, value= <<"2">> },
                      #option { label= <<"Option 3">>, value= <<"3">> }
                     ]
               },
      #button{ id = discard, body = <<"Discard">>, postback = discard}
    ].

event(init) ->
    {ok,GamePid} = game_session:start_link(self()),
    put(game_session, GamePid);

event(combo)  -> wf:info("Combo: ~p",[wf:q(dddiscard)]);
event(join)   -> wf:wire(join("1000001"));
event(attach) -> wf:wire(attach("'"++?TEST_TOKEN++"'"));
event(take)   -> wf:wire(take("1000001", wf:q(ddtake)));

event(discard) -> 
    TilesList = get(game_okey_tiles),
    {_, {C, V}} = lists:keyfind(erlang:list_to_binary(wf:q(dddiscard)), 1, TilesList),
    wf:wire(discard("1000001", erlang:integer_to_list(C), erlang:integer_to_list(V)));

event({server, {game_event, _, okey_game_started, Args}}) ->
    {_, Tiles} = lists:keyfind(tiles, 1, Args),
    TilesList = [{erlang:list_to_binary([erlang:integer_to_list(C), " ", erlang:integer_to_list(V)]), {C, V}} || {_, C, V} <- Tiles],
    wf:info("tiles ~p", [TilesList]),
    put(game_okey_tiles, TilesList),
    redraw_tiles(TilesList);
event({server, {game_event, _, okey_tile_discarded, Args}}) ->
    {_, {_, V, C}} = lists:keyfind(tile, 1, Args),
    TilesListOld = get(game_okey_tiles),
    TilesList = lists:keydelete({C, V}, 2, TilesListOld),
    put(game_okey_tiles, TilesList),
    redraw_tiles(TilesList);
%%event({server, {game_event, _, okey_tile_taken, Args}}) ->
%%    TilesList = get(game_okey_tiles),
%%    {_, Pile} = lists:keyfind(pile, 1, Args),
%%    redraw_tiles(TilesList);
event(Event)  -> wf:info("Event: ~p", [Event]).

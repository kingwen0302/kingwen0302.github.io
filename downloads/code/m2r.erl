%% ===========================================================================
%% @doc

%% @end
%% ===========================================================================
-module(m2r).
-author(zhaoming).
-version(1.0).
-date('2016-06-08').

-export([
         test/0
        ]).

-record(mapRecord, {
          a = 1
          ,b = 3
          ,c = 2
          ,d = 4
         }).

-define(map_to_record(Map, RecordName), 
        %% list_to_tuple(
        %%   lists:map( 
        %%     fun({__K__, __V__}) -> maps:get(__K__, Map, __V__) end, 
        %%     lists:zip([RecordName|record_info(fields, RecordName)], tuple_to_list(#RecordName{}))
        %%    )
        %%  )
        list_to_tuple( [maps:get(__K__, Map, __V__) || {__K__, __V__} <- lists:zip([RecordName|record_info(fields, RecordName)], tuple_to_list(#RecordName{})) ] )
       ).

-define(record_to_map(RecordName, Record),
        %% lists:foldl(
        %%   fun({__K__, __V__}, __Map__) -> maps:put(__K__, __V__, __Map__) end,
        %%   #{}, 
        %%   lists:zip(['__name__'|record_info(fields, RecordName)], tuple_to_list(Record))
        %%  )
        maps:from_list(lists:zip(['__name__'|record_info(fields, RecordName)], tuple_to_list(Record)))
       ).

test() ->
    Map = #{'__name__' => mapRecord, "a" => 1, b => 2},
    io:format("~p~n", [Map]),
    K = 1,
    R = ?map_to_record(Map, mapRecord),
    io:format("~p~n", [R]),
    ?record_to_map(mapRecord, #mapRecord{}).

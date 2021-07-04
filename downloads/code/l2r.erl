%% coding: latin-1
%%%-----------------------------------------------
%%% @doc
%%%     record,kvlist互转
%%%     包含头文件即可
%%% @end
%%%-----------------------------------------------
-module(l2r).

-include("rec_a.hrl").

-define(RECORD_NAME, '__record_name__').

-define(ERROR_MSG(Format, Args), io:format("[ERROR]" ++ Format ++ "\n", Args)).
-define(INFO_MSG(Format, Args), io:format("[INFO]" ++ Format ++ "\n", Args)).

-compile([{parse_transform, record_info_runtime}]).

-export([
         rec_to_kvlist/1,
         kvlist_to_rec/1
        ]).

-export([
         records/0,
         record_info_fields/1,
         record_info_size/1
        ]).

rec_to_kvlist(Rec) ->
    rec_to_kvlist_f1(Rec, 1).

rec_to_kvlist_f1(Rec, Depth) when Depth > 10 ->
    throw({error, Depth, Rec});
rec_to_kvlist_f1(Rec, Depth) when is_tuple(Rec) ->
    case is_record(Rec) of
        true ->
            RecName = erlang:element(1, Rec),
            Fields = [?RECORD_NAME|record_info_fields(RecName)],
            Values = tuple_to_list(Rec),
            Fun = fun({Field, Value}) when is_tuple(Value) ->
                          {Field, rec_to_kvlist_f1(Value, Depth + 1)};
                     ({Field, Value}) when is_list(Value) ->
                          {Field, [rec_to_kvlist_f1(V, Depth + 1) || V <- Value]};
                     ({Field, Value}) ->
                          {Field, Value}
                  end,
            lists:map(Fun, lists:zip(Fields, Values));
        false ->
            Rec
    end;
rec_to_kvlist_f1(Val, _) -> Val.

kvlist_to_rec(KvList) when is_list(KvList) ->
    case proplists:get_value(?RECORD_NAME, KvList) of
        undefined ->
            Fun = fun(Val) -> kvlist_to_rec(Val) end,
            lists:map(Fun, KvList);
        RecName ->
            InitList = lists:zip(
                         [?RECORD_NAME|record_info_fields(RecName)],
                         tuple_to_list(record_init(RecName))),
            Fun = fun(Field) ->
                          case proplists:get_value(Field, KvList) of
                              undefined ->
                                  proplists:get_value(Field, InitList);
                              Val when is_list(Val) ->
                                  kvlist_to_rec(Val);
                              Val ->
                                  Val
                          end
                  end,
            list_to_tuple(lists:map(Fun, [?RECORD_NAME|record_info_fields(RecName)]))
    end;
kvlist_to_rec(KvList) -> KvList.

is_record(Rec) when is_tuple(Rec), tuple_size(Rec) >= 1 ->
    RecName = erlang:element(1, Rec),

    is_list(record_info_fields(RecName))
    andalso length(tuple_to_list(Rec)) =:= record_info_size(RecName);
is_record(_Other) -> false.

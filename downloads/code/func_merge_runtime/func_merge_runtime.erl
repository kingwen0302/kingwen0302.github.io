%% coding: latin-1
%%%-----------------------------------------------
%%% @author kingwen0302 <kingwen0302@msn.com>
%%% @since 2018-09-12 11:13:37
%%% @doc
%%%     将多个beam的导出函数合并到一个文件
%%%     并且可以重载函数
%%%
%%%     使用
%%%     ```
%%%     -compile([{parse_transform, func_merge_runtime}]).
%%%     -load_all(a).
%%%     -load_func({a, [f1/0, f2/1]}).
%%%     ```
%%%
%%% @end
%%%-----------------------------------------------
-module(func_merge_runtime).

-record(state, {
          export_list = [],
          overload_list = [],
          ebin = "./",
          module
         }).

-record(mfa, {m, f, a, key}).

-export([parse_transform/2]).

parse_transform(Forms, CompileOptions) ->
    EbinPath = proplists:get_value(outdir, CompileOptions, "./"),
    NewForms = forms_process(Forms, [], #state{ebin = EbinPath}),
    NewForms.

forms_process([{eof, _} = EOF], L, #state{export_list = []}) ->
    lists:reverse([EOF|L]);
forms_process([{eof, _} = EOF], L, #state{export_list = ExList}) ->
    FormList1 = lists:map(fun(MFA) -> export_function(MFA) end, ExList),
    lists:reverse([EOF] ++ FormList1 ++ L);

forms_process([{attribute, _, module, M} = H|Forms], L, State) ->
    forms_process(Forms, [H|L], State#state{module = M});

forms_process([{attribute, _, load_all, M} = _H|Forms], L, #state{ebin = EbinPath} = State) ->
    code:add_path(EbinPath),
    List = M:module_info(exports),
    NewState = do_load_func(M, List, State),
    forms_process(Forms, L, NewState);

forms_process([{attribute, _, load_func, {M, List}} = _H|Forms], L, State) ->
    NewState = do_load_func(M, List, State),
    forms_process(Forms, L, NewState);

forms_process([{function, _, F, ArgLen, _} = H|Forms], L,
              #state{export_list = ExList, overload_list = OvList} = State) ->
    Key = {F, ArgLen},
    {NewExList, NewOvList} =
    case lists:keyfind(Key, #mfa.key, ExList) of
        false -> {ExList, OvList};
        #mfa{} ->
            io:format("Warning: ~p/~p overloaded ...~n", [F, ArgLen]),
            ExList1 = lists:keydelete(Key, #mfa.key, ExList),
            OvList1 = lists:keystore(Key, #mfa.key, OvList, #mfa{f = F, a = ArgLen, key = Key}),
            {ExList1, OvList1}
    end,
    forms_process(Forms, [H|L], State#state{export_list = NewExList, overload_list = NewOvList});

forms_process([H | Forms], L, State) ->
    forms_process(Forms, [H | L], State).

export_function(#mfa{m = M, f = F, a = ArgLen}) ->
    Fun = fun(Nth) ->
                  {var, 1, erlang:list_to_atom(io_lib:format("A~p", [Nth]))}
          end,
    VarList = lists:map(Fun, lists:seq(1, ArgLen)),
    {function, 1, F, ArgLen,
     [{clause, 1,
       VarList, [],
       [{call, 1,
         {remote, 1, {atom, 1, M}, {atom, 1, F}},
         VarList
        }]
      }]}.

do_load_func(M, List, #state{export_list = ExList, overload_list = OvList} = State) ->
    Fun = fun({module_info, _}, Acc) -> Acc;
             ({F, ArgLen}, {ExList1, OvList1}) ->
                  MFA = #mfa{m = M, f = F, a = ArgLen, key = {F, ArgLen} },
                  ExList2 =
                  case lists:keymember(MFA#mfa.key, #mfa.key, OvList1) of
                      false ->
                          case lists:keyfind(MFA#mfa.key, #mfa.key, ExList1) of
                              false -> [MFA|ExList1];
                              #mfa{} = FindMFA ->
                                  io:format("Warning: ~p:~p/~p function duplicate, Used: ~p/~p -> ~p:~p/~p~n",
                                            [M,F,ArgLen,
                                             FindMFA#mfa.f, FindMFA#mfa.a,
                                             FindMFA#mfa.m, FindMFA#mfa.f, FindMFA#mfa.a]),
                                  ExList1
                          end;
                      true ->
                          ExList1
                  end,
                  {ExList2, OvList1}
          end,
    {NewExList, NewOvList} = lists:foldl(Fun, {ExList, OvList}, List),
    State#state{export_list = NewExList, overload_list = NewOvList}.

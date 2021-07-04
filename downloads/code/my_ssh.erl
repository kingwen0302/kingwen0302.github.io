%% ===========================================================================
%% @doc
%% TODO 模块描述.
%% @end
%% ===========================================================================
-module(my_ssh).
-author(kingwen0302).
-version(1.0).
-date('2016-03-15').

-export([exec/4]).

%% @doc ssh登录执行命令脚本
%% 
%% for example:
%% ```
%% my_ssh:exec("192.168.6.77", 22, [{user, "root"}, {password, "123456"}], "export LANG=en.UTF-8 && ls -l").
%% '''
%% 这个只是个测试脚本
%% 
-spec exec(Host, Port, Options, Cmd) -> Return when
    Host        :: string(),
    Port        :: integer(),
    Options     :: list(),
    Cmd         :: string(),
    Return      :: {ExitStatus, Result},
    ExitStatus  :: integer(),
    Result      :: string().

exec(Host, Port, Options, Cmd) ->
    ssh:start(),
    {ok, Ref} = ssh:connect(Host, Port, Options),
    {ok, ChanID} = ssh_connection:session_channel(Ref, infinity),
    case ssh_connection:exec(Ref, ChanID, Cmd, infinity) of
        success ->
            {ExitStatus, ReturnStr} = wait(Ref),
            io:format("ExitStatus:~p~n", [ExitStatus]),
            io:format("ReturnStr:~n~s~n", [ReturnStr]),
            ok;
        _ -> error
    end.

wait(Ref) ->
    wait(Ref, 0, "").

wait(Ref, ExitStatus, Str) ->
    receive
        {ssh_cm, Ref, Msg} ->
            case Msg of
                {closed, _ChanID} ->
                    {ExitStatus, Str};
                {data, _ChanID, _, RecvStr} ->
                    NewStr = io_lib:format("~s~s", [Str, RecvStr]),
                    wait(Ref, ExitStatus, NewStr);
                {exit_status, _ChanID, Status} ->
                    wait(Ref, Status, Str);
                _ ->
                    wait(Ref, ExitStatus, Str)
            end
    end.

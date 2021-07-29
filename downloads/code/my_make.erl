%% ===========================================================================
%% @doc
%% 个人编译模块
%% 编译所有文件到ebin,ebin1,/data/t/ebin2目录
%% erl -s my_make all ebin ebin1 /data/t/ebin2
%% 编译单个文件到ebin目录
%% erl -s my_make file src/a ebin
%% @end
%% ===========================================================================
-module(my_make).
-author(zhaoming).
-version(1.0).
-date('2016-03-29').

-export([all/1, file/1]).

all([]) -> 
    msg(not_dir),
    erlang:halt();
all(OutDirList) -> 
    timer:sleep(1000),
    io:format("~n"),
    Result = do_make(OutDirList),
    msg(Result),
    erlang:halt().

do_make([]) -> up_to_date;
do_make([OutDirAtom|OutDirList]) ->
    OutDir = atom_to_list(OutDirAtom),
    Options = [{outdir, OutDir}, {d, debug}],
    msg(io_lib:format("Dir:~p", [filename:absname(OutDir)])),
    case filelib:is_dir(OutDir) of
        true -> ok;
        false -> 
            ok = filelib:ensure_dir(OutDir), 
            ok = file:make_dir(OutDir),
            ok
    end,
    case make:all(Options) of 
        up_to_date -> do_make(OutDirList); 
        error -> error
    end.

file([File, OutDirAtom|_]) ->
    do_file(File, OutDirAtom),
    erlang:halt().

do_file(File, OutDirAtom) ->
    {ok, [{_, Options}|_]} = file:consult("Emakefile"),
    OutDir = atom_to_list(OutDirAtom),
    R = compile:file(atom_to_list(File), Options ++ [{outdir, OutDir}, {d, debug}]),
    msg(R).

msg(Msg) ->
    case Msg of
        Msg when is_list(Msg); is_binary(Msg) -> 
            io:format("~s~n", [Msg]);
        _ -> io:format("~p~n", [Msg])
    end.

%% coding: latin-1
%%! -smp enable -name server_ctl_gui@127.0.0.1 -setcookie qqjy -noshell
%%%-----------------------------------------------
%%% 一个界面管理所有节点信息
%%%
%%% escript server_ctl_gui.erl --log_file E:/qqjy/server_ctl_gui.log --project_root E:/qqjy/qqjy_server/config
%%%
%%% 已知问题:
%%% 1. 在使用`RunHiddenConsole erl` 后, `observer:start()`会失效
%%%
%%%-----------------------------------------------

-include_lib("wx/include/wx.hrl").
-include_lib("kernel/include/file.hrl").

-define(APP_NAME, server_ctl_gui).

-define(DEBUG_MSG(Format), ?DEBUG_MSG(Format, [])).
%% ?LINE + 1 应该是因为 `-smp ...` 的原因
-define(DEBUG_MSG(Format, Args),
        lists:foldl(
          fun(IO, Str) when is_pid(IO) ->
                  io:format(IO, "~s", [Str]),
                  Str;
             (wx, Str) ->
                  case get_env(parent_pid) of
                      undefined ->
                          set_env(wx_log_list, get_env(wx_log_list, []) ++ [Str]);
                      _ ->
                          lists:foreach(
                            fun(_X_) -> get_env(parent_pid) ! {log_wx, Str} end, 
                            get_env(wx_log_list, []) ++ [Str]),
                          set_env(wx_log_list, [])
                  end,
                  Str;
             (_, Str) ->
                  io:format("~ts", [Str]),
                  Str
          end,
          unicode:characters_to_binary(io_lib:format("~s ~p [line:~p] " ++ Format ++ "~n", [time_format(), self(), ?LINE + 1 | Args])),
          lists:usort([undefined, wx, application:get_env(?APP_NAME, log_pid, undefined)])
         )).

-record(wx_elem_cfg, {
          id = 0,
          name = "",
          type = 0, %% button | text
          start_cmd_list = [],  %% 字符串命令 | {call, {M, F, A}}, {mfa, {Fun, Args}}
          over_cmd_list = [],
          node = undefined,
          log_file = ""
         }).

-record(wx_elem_state, {
          id = 0,
          wx,
          status = over, %% over | start
          log_pid
         }).

-record(state, {
          frame,
          btn_list = [],
          text_list = [],
          log_wx,
          pid
         }).

-define(START_STR, "【开启】").
-define(CLOSE_STR, "【关闭】").

%% 按钮
-define(BUTTON_SIZE_X, 100).
-define(BUTTON_SIZE_Y, 30).

%% 日志框
-define(TEXT_SIZE_X, 1680).
-define(TEXT_SIZE_Y, 400).

%% 初始化显示行数
-define(SHOW_LINES_INIT, 10).

-define(ERL_HEAD, "RunHiddenConsole D:/erl6.2/bin/erl +P 6400 -smp auto -pa ../ebin -noshell -noinput -setcookie qqjy -boot start_sasl ").
-define(WERL_HEAD, "start D:/erl6.2/bin/werl +P 6400 -smp auto -pa ../ebin -setcookie qqjy ").

%% 节点名字
-define(NODE_GAME,  'qqjy_game1@127.0.0.1').
-define(NODE_GAME_2,'qqjy_game2@127.0.0.1').
-define(NODE_CROSS, 'qqjy_cross1@127.0.0.1').
-define(NODE_MGR,   'qqjy_mgr1@127.0.0.1').
-define(NODE_FLASH, 'qqjy_game_flash1@127.0.0.1').

%% 节点启动命令
-define(START_GAME_CMD,     ?ERL_HEAD ++ "-name " ++ atom_to_list(?NODE_GAME)   ++ " -config run_game -s main server_start").
-define(START_GAME_2_CMD,   ?ERL_HEAD ++ "-name " ++ atom_to_list(?NODE_GAME_2) ++ " -config run_game2 -s main server_start").
-define(START_CROSS_CMD,    ?ERL_HEAD ++ "-name " ++ atom_to_list(?NODE_CROSS)  ++ " -config run_cross -s main server_start").
-define(START_MGR_CMD,      ?ERL_HEAD ++ "-name " ++ atom_to_list(?NODE_MGR)    ++ " -config run_mgr -s main server_start").
-define(START_FLASH_CMD,    ?ERL_HEAD ++ "-name " ++ atom_to_list(?NODE_FLASH)  ++ " -config flash -s main flash_start").
-define(START_MAKE,         ?WERL_HEAD ++ "-eval \"case u:d() of up_to_date -> timer:sleep(5000), init:stop(); _ -> error end\"").
-define(START_MAKE_FUNC,    ?WERL_HEAD ++ "-eval \"case u:m([fair_1v1]) of up_to_date -> timer:sleep(60000), init:stop(); _ -> error end\"").
-define(START_GAME_DEBUG,   ?WERL_HEAD ++ "-name debug_1@127.0.0.1 -remsh "     ++ atom_to_list(?NODE_GAME)).
-define(START_CROSS_DEBUG,  ?WERL_HEAD ++ "-name debug_cross@127.0.0.1 -remsh " ++ atom_to_list(?NODE_CROSS)).
-define(START_MGR_DEBUG,    ?WERL_HEAD ++ "-name debug_mgr@127.0.0.1 -remsh "   ++ atom_to_list(?NODE_MGR)).
-define(START_GUI_DEBUG,    ?WERL_HEAD ++ "-name debug_gui@127.0.0.1 -remsh "   ++ atom_to_list('server_ctl_gui@127.0.0.1')).

%% 日志文件
-define(FILE_GAME_LOG,  "E:/qqjy/qqjy_server/logs/game_200001/console.txt").
-define(FILE_CROSS_LOG, "E:/qqjy/qqjy_server/logs/cross/console.txt").

%% 玩家列表url
-define(URL_PLAYER_LIST, "http://127.0.0.1:7010/debug/user_list?is_show_guest=1&last_days=10&client=1").

%% 按钮列表, 横向排序
wx_btn_list() ->
    [
     #wx_elem_cfg{
        id = 101, name = "游戏服", type = button,
        start_cmd_list = [?START_GAME_CMD],
        over_cmd_list = [{call, {main, shutdown, []}}],
        node = ?NODE_GAME
       },
     #wx_elem_cfg{
        id = 1011, name = "游戏服2", type = button,
        start_cmd_list = [?START_GAME_2_CMD],
        over_cmd_list = [{call, {main, shutdown, []}}],
        node = ?NODE_GAME_2
       },
     #wx_elem_cfg{
        id = 102, name = "跨服", type = button,
        start_cmd_list = [?START_CROSS_CMD],
        over_cmd_list = [{call, {main, shutdown, []}}],
        node = ?NODE_CROSS
       },
     #wx_elem_cfg{
        id = 103, name = "管理服", type = button,
        start_cmd_list = [?START_MGR_CMD],
        over_cmd_list = [{call, {main, shutdown, []}}],
        node = ?NODE_MGR
       },
     #wx_elem_cfg{
        id = 104, name = "FLASH", type = button,
        start_cmd_list = [?START_FLASH_CMD],
        over_cmd_list = [{call, {main, flash_stop, []}}],
        node = ?NODE_FLASH
       },
     #wx_elem_cfg{
        id = 105, name = "一键启动所有服", type = button,
        start_cmd_list = [
                          ?START_FLASH_CMD,
                          ?START_MGR_CMD,
                          ?START_CROSS_CMD,
                          ?START_GAME_CMD
                         ],
        node = undefined
       },
     #wx_elem_cfg{
        id = 106, name = "编译", type = button,
        start_cmd_list = [?START_MAKE],
        node = undefined
       },
     #wx_elem_cfg{
        id = 1061, name = "编译功能", type = button,
        start_cmd_list = [?START_MAKE_FUNC],
        node = undefined
       },
     #wx_elem_cfg{
        id = 107, name = "玩家列表", type = button,
        start_cmd_list = [{mfa, {fun wx_misc:launchDefaultBrowser/1, [?URL_PLAYER_LIST]}}],
        node = undefined
       },
     #wx_elem_cfg{
        id = 108, name = "DEBUG_GAME", type = button,
        start_cmd_list = [?START_GAME_DEBUG],
        node = undefined
       },
     #wx_elem_cfg{
        id = 109, name = "DEBUG_CROSS", type = button,
        start_cmd_list = [?START_CROSS_DEBUG],
        node = undefined
       },
     #wx_elem_cfg{
        id = 110, name = "DEBUG_MGR", type = button,
        start_cmd_list = [?START_MGR_DEBUG],
        node = undefined
       },
     #wx_elem_cfg{
        id = 111, name = "DEBUG_GUI", type = button,
        start_cmd_list = [?START_GUI_DEBUG],
        node = undefined
       }
    ].

%% 日志列表, 纵向排序
wx_text_list() ->
    [
     #wx_elem_cfg{
        id = 201, type = text, name = "游戏服日志",
        log_file = ?FILE_GAME_LOG
       },
     #wx_elem_cfg{
        id = 202, type = text, name = "跨服日志",
        log_file = ?FILE_CROSS_LOG
       }
    ].

main(Args) ->
    parse_args(Args),
    application:load({application, ?APP_NAME, []}),
    set_env(parent_pid, self()),
    ?DEBUG_MSG("欢迎使用GUI版, Powered by kingwen0302"),
    case get_env(log_file) of
        undefined -> ?DEBUG_MSG("缺少log_file配置");
        LogFile ->
            {ok, IO} = file:open(LogFile, [append]),
            set_env(log_pid, IO)
    end,
    State = make_window(),
    self() ! {chk},
    loop (State).

make_window() ->
    case get_env(project_root) of
        undefined -> ?DEBUG_MSG("缺少project_root配置");
        Dir -> file:set_cwd(Dir)
    end,
    {ok, RootDir} = file:get_cwd(),
    ?DEBUG_MSG("项目目录: ~s", [RootDir]),
    Server = wx:new(),
    Frame = wxFrame:new(Server,
                        -1,
                        "QQJY-国服-开发-节点管理 POWERED BY kingwen0302",
                        [{size,{0, 0}}, {style, ?wxDEFAULT_FRAME_STYLE bor ?wxMAXIMIZE}]
                       ),
    Panel = wxScrolledWindow:new(Frame),
    wxPanel:setBackgroundColour(Panel, ?wxLIGHT_GREY),

    Sz = wxBoxSizer:new(?wxVERTICAL),

    ButtonSizer = wxStaticBoxSizer:new(?wxHORIZONTAL, Panel, [{label, "命令按钮"}]),

    StockSz = wxGridSizer:new(0,6,3,3),

    BtnList = create_btn_list(Panel, wx_btn_list()),
    SzFlags = [{proportion, 0}, {border, 4}, {flag, ?wxALL}],
    [wxSizer:add(StockSz, Btn, SzFlags) || #wx_elem_state{wx = Btn} <- BtnList],
    wxSizer:add(ButtonSizer, StockSz, SzFlags),

    Log = wxTextCtrl:new(Panel, 0, [
                                                    {size, {1000, 100}},
                                                    {style, ?wxTE_READONLY bor ?wxTE_MULTILINE}
                                                   ]),
    wxSizer:add(ButtonSizer, Log, SzFlags),
    wxSizer:add(Sz, ButtonSizer, SzFlags),

    TextList = create_text_list(Panel, wx_text_list()),
    Expand  = [{proportion, 0}, {border, 4}, {flag, ?wxALL bor ?wxEXPAND}],
    Fun = fun(#wx_elem_state{id = Id, wx = Text}) ->
                  Name = case lists:keyfind(Id, #wx_elem_cfg.id, wx_text_list()) of
                             #wx_elem_cfg{name = Name1} -> Name1;
                             _ -> ""
                         end,
                  TextSizer = wxStaticBoxSizer:new(?wxVERTICAL, Panel, [{label, Name}]),
                  wxSizer:add(TextSizer, Text, Expand),
                  {TextSizer, Expand}
          end,
    [wxSizer:add(Sz, TextSizer, Flag) || {TextSizer, Flag} <- lists:map(Fun, TextList)],

    wxWindow:setSizer(Panel, Sz),
    wxSizer:layout(Sz),
    wxWindow:refresh(Panel),
    wxScrolledWindow:setScrollRate(Panel, 5, 5),

    wxFrame:show(Frame),

    wxFrame:connect(Frame, close_window),
    wxPanel:connect(Panel, command_button_clicked),

    #state{frame = Frame, btn_list = BtnList, text_list = TextList, log_wx = Log, pid = self()}.

loop(State) ->
    receive
        Msg ->
            case catch do_loop(Msg, State) of
                {'EXIT', Reason} ->
                    ?DEBUG_MSG("Msg:~p Reason:~p", [Msg, Reason]),
                    loop(State);
                _ ->
                    loop(State)
            end
    end.

%% 退出界面
do_loop(#wx{event=#wxClose{}}, #state{pid = Pid} = State) ->
    if
        Pid =/= self() -> Pid ! { -1 };
        true -> ok
    end,
    ?DEBUG_MSG("~p Closing window",[self()]),
    close(State),
    ok;
%% 退出界面
do_loop(#wx{id = ?wxID_EXIT, event=#wxCommand{type = command_button_clicked} }, #state{pid = Pid} = State) ->
    if
        Pid =/= self() -> Pid ! { -1 };
        true -> ok
    end,
    ?DEBUG_MSG("~p Closing window",[self()]),
    close(State),
    ok;
%% 按钮点击
do_loop(#wx{id =Id, event=#wxCommand{type = command_button_clicked}}, #state{btn_list = BtnList} = State) ->
    Cfg = lists:keyfind(Id, #wx_elem_cfg.id, wx_btn_list()),
    case is_record(Cfg, wx_elem_cfg) of
        false -> throw(ok);
        true -> skip
    end,
    #wx_elem_cfg{start_cmd_list = StartCmdList, over_cmd_list = OverCmdList, node = Node} = Cfg,
    Fun = fun(Cmd) when is_list(Cmd) ->
                  ?DEBUG_MSG("字符串命令: ~p", [Cmd]),
                  spawn(fun() -> os:cmd(Cmd) end);
             ({call, {M, F, A}}) ->
                  ?DEBUG_MSG("节点Call: rpc:call(~p, ~p, ~p, ~p)", [Node, M, F, A]),
                  rpc:call(Node, M, F, A);
             ({mfa, {M, F, A}}) ->
                  ?DEBUG_MSG("函数调用: ~p:~p Args:~p", [M, F, A]),
                  apply(M, F, A);
             ({mfa, {F, A}}) ->
                  ?DEBUG_MSG("函数调用: ~p Args:~p", [F, A]),
                  apply(F, A)
          end,
    case lists:keyfind(Id, #wx_elem_state.id, BtnList) of
        #wx_elem_state{status = over} ->
            ?DEBUG_MSG("开始 ~p", [Id]),
            lists:foreach(Fun, StartCmdList);
        #wx_elem_state{status = start} ->
            ?DEBUG_MSG("关闭 ~p", [Id]),
            lists:foreach(Fun, OverCmdList);
        _ -> skip
    end,
    loop(State);
%% 定时检查
do_loop({chk}, #state{btn_list = BtnList, text_list = TextList, pid = Pid} = State) ->
    Fun = fun(#wx_elem_state{id = Id, wx = Text, log_pid = LogPid} = Elem) ->
                  TailEXE = os:find_executable("tail"),
                  case lists:keyfind(Id, #wx_elem_cfg.id, wx_text_list()) of
                      #wx_elem_cfg{log_file = LogFile} when TailEXE =:= false ->
                          read_line(Id, Text, LogFile),
                          Elem;
                      #wx_elem_cfg{log_file = LogFile} when LogPid =:= undefined ->
                          NewLogPid = spawn_link(fun() -> read_line_by_tail(Pid, TailEXE, Id, LogFile) end),
                          Elem#wx_elem_state{log_pid = NewLogPid};
                      _ -> Elem
                  end
          end,
    NewTextList = lists:map(Fun, TextList),

    Fun1 = fun(#wx_elem_state{id = Id, wx = Btn} = Elem) ->
                   case lists:keyfind(Id, #wx_elem_cfg.id, wx_btn_list()) of
                       #wx_elem_cfg{name = Name, node = Node} when Node =/= undefined ->
                           case net_adm:ping(Node) of
                               pong ->
                                   wxButton:setLabel(Btn, ?CLOSE_STR ++ Name),
                                   Elem#wx_elem_state{status = start};
                               _ ->
                                   wxButton:setLabel(Btn, ?START_STR ++ Name),
                                   Elem#wx_elem_state{status = over}
                           end;
                       _ -> Elem
                   end
           end,
    NewBtnList = lists:map(Fun1, BtnList),
    NewState = State#state{btn_list = NewBtnList, text_list = NewTextList},
    %% 执行完成后在开启下次定时器
    erlang:send_after(2000, self(), {chk}),
    loop(NewState);
%% 使用port的日志输出
do_loop({log, Id, Data}, #state{text_list = TextList} = State) ->
    case lists:keyfind(Id, #wx_elem_state.id, TextList) of
        #wx_elem_state{wx = Text} ->
            wxTextCtrl:appendText(Text, Data ++ "\n");
        _ ->
            ?DEBUG_MSG("Log: Id:~p", [Id])
    end,
    loop(State);
do_loop({log_wx, Str}, #state{log_wx = Text} = State) ->
    wxTextCtrl:appendText(Text, Str),
    loop(State);
do_loop(Msg, State) ->
    ?DEBUG_MSG("not match:~p", [Msg]),
    loop(State).

read_line_by_tail(Pid, TailEXE, Id, LogFile) ->
    process_flag(trap_exit, true),
    PortOptions = [
                   exit_status,
                   {line, 1024},
                   {args, ["-F", LogFile]},
                   in
                  ],
    Port = erlang:open_port({spawn_executable, TailEXE}, PortOptions),
    read_line_by_tail_loop(Pid, Id, Port).
read_line_by_tail_loop(Pid, Id, Port) ->
    receive
        {Port, {data, {eol, Data}}} ->
            Pid ! {log, Id, Data},
            read_line_by_tail_loop(Pid, Id, Port);
        {Port, {data, {noeol, Data}}} ->
            Pid ! {log, Id, Data},
            read_line_by_tail_loop(Pid, Id, Port);
        {close} ->
            %% 结束端口开的系统进程
            PortInfo = erlang:port_info(Port),
            erlang:port_close(Port),
            case proplists:get_value(os_pid, PortInfo) of
                undefined -> skip;
                OsPid -> kill_by_os(OsPid)
            end,
            ok;
        Any ->
            ?DEBUG_MSG("Any:~p", [Any]),
            read_line_by_tail_loop(Pid, Id, Port)
    end.

%% 自己实现的输出
%% 在没有tail的情况下使用
read_line(Id, Text, File) ->
    MaxLine = case get_env({max_line, Id, File}) of
                  undefined -> max_line(File) - ?SHOW_LINES_INIT;
                  MaxLine1 -> MaxLine1
              end,
    OldCTime = case get_env({ctime, Id, File}) of
                   undefined -> get_ctime(File);
                   CTime1 -> CTime1
               end,

    NowCtime = get_ctime(File),
    MaxLine = case OldCTime =:= NowCtime of
                  true -> MaxLine;
                  false ->
                      set_env({max_line, Id, File}, 0),
                      0
              end,

    case file:open(File, [read]) of
        {ok, FD} ->
            set_env({max_line, Id, File}, MaxLine),
            read_line(Id, Text, File, FD, 1, MaxLine);
        _ ->
            set_env({max_line, Id, File}, 0)
    end.
read_line(Id, Text, File, FD, Line, MaxLine) ->
    case file:read_line(FD) of
        {ok, Data} when Line > MaxLine ->
            wxTextCtrl:appendText(Text, Data),
            set_env({max_line, Id, File}, Line),
            read_line(Id, Text, File, FD, Line + 1, MaxLine);
        {ok, _Data} ->
            read_line(Id, Text, File, FD, Line + 1, MaxLine);
        eof ->
            file:close(FD)
    end.

%% 获取文件最大行数
max_line(File) ->
    case file:open(File, [read]) of
        {ok, FD} -> max_line(FD, 0);
        _ -> 0
    end.
max_line(FD, Line) ->
    case file:read_line(FD) of
        {ok, _Data} ->
            max_line(FD, Line + 1);
        eof ->
            file:close(FD),
            Line
    end.

get_ctime(File) ->
    case file:read_file_info(File) of
        {ok, #file_info{ctime = Ctime}} -> Ctime;
        _ -> undefined
    end.

%% 创建按钮
create_btn_list(Panel, CfgList) ->
    Fun = fun(#wx_elem_cfg{id = Id, name = Name}) ->
                  Btn = wxButton:new(Panel, Id, [{label, Name}, {size, {?BUTTON_SIZE_X, ?BUTTON_SIZE_Y}}]),
                  %% Btn = wxButton:new(Panel, Id, [{label, Name}]),
                  #wx_elem_state{id = Id, wx = Btn}
          end,
    lists:map(Fun, CfgList).
%% 创建日志框
create_text_list(Panel, CfgList) ->
    Fun = fun(#wx_elem_cfg{id = Id}) ->
                  Text = wxTextCtrl:new(Panel, Id, [
                                                    {size, {?TEXT_SIZE_X, ?TEXT_SIZE_Y}},
                                                    {style, ?wxTE_READONLY bor ?wxTE_MULTILINE}
                                                   ]),
                  %% TextAttr = wxTextAttr:new(),
                  %% wxTextAttr:setBackgroundColour(TextAttr, {255, 0, 0}),
                  %% wxTextAttr:setFont(TextAttr, wxFont:new(20, ?wxDEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_NORMAL)),
                  %% %% TextAttr = wxTextAttr:new({255, 0, 0}, [
                  %% %%                             {colBack, {255, 0, 0}},
                  %% %%                             {font, wxFont:new(20, ?wxDEFAULT, ?wxFONTSTYLE_NORMAL, ?wxFONTWEIGHT_NORMAL)}
                  %% %%                            ]),
                  %% wxTextCtrl:setDefaultStyle(Text, TextAttr),
                  #wx_elem_state{id = Id, wx = Text}
          end,
    lists:map(Fun, CfgList).

%% 界面关闭
close(#state{frame = Frame, text_list = TextList}) ->
    Fun = fun(#wx_elem_state{log_pid = Pid}) -> Pid ! {close} end,
    lists:foreach(Fun, TextList),
    timer:sleep(500),
    wxWindow:destroy(Frame),
    wx:destroy(),
    case get_env(log_pid) of
        undefined -> skip;
        IO -> file:close(IO)
    end,
    kill_by_os(os:getpid()),
    ok.

%% 结束系统进程
kill_by_os(OsPid) ->
    case os:type() of
        {win32, _} ->
            os:cmd(lists:concat(["tskill ", OsPid]));
        _ ->
            os:cmd(lists:concat(["kill -9 ", OsPid]))
    end.

%% 时间格式化
time_format() ->
    {{Y, M, D}, {HH, MM, SS}} = calendar:universal_time_to_local_time(calendar:universal_time()),
    I2L = fun(I) when I < 10  -> [$0, $0+I];
             (I)              -> integer_to_list(I)
          end,
    io_lib:format("~s-~s-~s ~s:~s:~s", [I2L(Y), I2L(M), I2L(D), I2L(HH), I2L(MM), I2L(SS)]).

parse_args([]) -> ok;
parse_args([Help|_]) when Help =:= "-h";
                          Help =:= "--help" ->
    ?DEBUG_MSG("================================================"),
    ?DEBUG_MSG("Args: --log_file FileName --project_root CfgDir "),
    ?DEBUG_MSG("================================================"),
    halt(0);
parse_args(["--log_file", FileName|OtherArgs]) ->
    set_env(log_file, FileName),
    parse_args(OtherArgs);
parse_args(["--project_root", DirName|OtherArgs]) ->
    set_env(project_root, DirName),
    parse_args(OtherArgs);
parse_args([_PosPar|OtherArgs]) ->
    parse_args(OtherArgs).

set_env(Key, Val) ->
    application:set_env(?APP_NAME, Key, Val).
get_env(Key) -> get_env(Key, undefined).
get_env(Key, Default) ->
    application:get_env(?APP_NAME, Key, Default).

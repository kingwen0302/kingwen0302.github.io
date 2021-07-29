#encoding:gbk

$cur_dir = Split-Path $MyInvocation.MyCommand.Path
$dir_main = "$cur_dir/../"
$dir_erl = $dir_main
$dir_log = "$dir_erl/logs"
$werl = "werl"
$erl = "erl"
$node_name = "cymmo"
$node_domain = "127.0.0.1"
$cookie = "cy_log"
$erl_port_min = 41001
$erl_port_max = 41100

$param_kernel = "-kernel inet_dist_listen_min $erl_port_min -kernel inet_dist_listen_max $erl_port_max"
$param_other = "+P 204800 -smp enable -server_base $dir_main -setcookie $cookie"
$param_env = "-evn ERL_MAX_PORTS 10240"
$param_pa = "-pa $dir_erl/config -pa $dir_erl/ebin -pa $dir_erl/baseebin"

$param_config_game = "-config $dir_erl/config/run_game"
$game_dump_log_file = "-env ERL_CRASH_DUMP $dir_log/game_crash.dump"

$conf = @{
    cur_dir            = $cur_dir;
    dir_main           = $dir_main;
    dir_erl            = $dir_erl;
    dir_log            = $dir_log;
    werl               = $werl;
    erl                = $erl;
    node_name          = $node_name;
    node_domain        = $node_domain;
    cookie             = $cookie;
    erl_port_min       = $erl_port_min;
    erl_port_max       = $erl_port_max;

    param_kernel       = $param_kernel;
    param_other        = $param_other;
    param_env          = $param_env;
    param_pa           = $param_pa;
    
    param_config_game  = $param_config_game;
    game_dump_log_file = $game_dump_log_file
}

. (Join-Path $conf["cur_dir"] funlib.ps1)

if ($args.Count -eq 0) {
    fun_wait_input $conf
}
else {
    fun_run $conf $args[0]
}

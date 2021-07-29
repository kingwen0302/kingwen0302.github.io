#encoding:gbk

function fun_make($conf){
    $src = $conf["dir_main"] + "/src"
    $inc = $conf["dir_main"] + "/include"
    $timefile = $conf["dir_main"] + "/timefile"
    $latestTime = $(Get-Item $timefile).LastWriteTime
    $now = $(Get-Date)

    function get_hrl_str(){
        begin{ $list = @() }
        process{ $list += $_.Name }
        end{
            $str = $list -join "|"
            if($str -ne ""){
                $str = "($str)"
            }
            $str
        }
    }
    $chhrl_str = Get-ChildItem $inc -Include *.hrl -Recurse | Where-Object {$_.LastWriteTime -gt $latestTime} | get_hrl_str

    ## 使用管道获取变化的文件
    ## 1. 获取所有文件
    ## 2. 检测变化文件
    ## 3. 生成文件全名列表
    function get_erl_list(){
        ## 每次编译100个文件,防止文件过多造成字符串过长报错
        ## https://support.microsoft.com/zh-cn/help/830473/command-prompt-cmd-exe-command-line-string-limitation
        begin{
            $ii = 0
            $list1 = @()
            $list = @()
        }
        process{
            $f = $_.FullName -replace "\\", "/"
            $f = "`\`"$f`\`""
            $list1 += $f
            $i++
            if ($i % 2 -eq 0){
                $list += $list1 -join ","
                $i = 0
                $list1 = @()
            }
        }
        end{
            if($list1){
                $list += $list1 -join ","
            }
            $list
        }
    }
    $erl_list = Get-ChildItem $src -Include *.erl -Exclude .svn,.git -Recurse | Where-Object {
        if ( $(Get-Item $_.FullName).LastWriteTime -gt $latestTime ){
            return $_
        }
        if($chhrl_str -eq ""){
            return $false
        } 
        if (Select-String -Path $_.FullName -Pattern $chhrl_str -Quiet) {
            return $_
        }else{
            return $false
        }
    } | get_erl_list
    
    Set-Location $conf["dir_erl"]
    ## 在windows下
    ## 直接mmake:files(500, [])无效
    ## 必须mmake:files(500, [], Opts)
    ## why?
    $cmd_str = '{0} {1} -noshell -eval "{{ok,[{{_, Opts}}|_]}}=file:consult(\"./Emakefile\"),case mmake:files(500,[{2}], Opts) of up_to_date -> init:stop(); _ -> init:stop(1) end"'
    $compile_status = $true
    if($erl_list.gettype().Name -eq "String"){
        $erl_list = @() + $erl_list
    }
    for ($i = 0; $i -lt $erl_list.Count; $i++) {
        $erl_str = $erl_list[$i]
        $cmd = $cmd_str -f $conf["erl"], $conf["param_pa"], $erl_str
        cmd /C $cmd
        if ($?) {
            continue
        }else{
            $compile_status = $false
            break
        }
    }
    # $cmd = $cmd_str -f $conf["erl"], $conf["param_pa"], $erl_str
    cmd /C $cmd
    if ($compile_status) {
        Write-Output "=============> 编译成功"
        $now.ToString() | Out-File $timefile -Append
        (Get-Item $timefile).LastWriteTime = $now
    }else{
        Write-Error "==============> 编译失败"
    }
}

function fun_start_game ($conf) {
    $node_name = $conf["node_name"]
    $node_domain = $conf["node_domain"]
    $param_pa = $conf["param_pa"]
    $param_kernel = $conf["param_kernel"] 
    $param_env = $conf["param_env"]
    $game_dump_log_file = $conf["game_dump_log_file"]
    $param_other = $conf["param_other"]
    $param_config_game = $conf["param_config_game"]
    Set-Location $conf["dir_erl"]
    $arg_str = "-name ${node_name}_game@$node_domain"
    $arg_str += " $param_pa $param_kernel $param_env"
    $arg_str += " $game_dump_log_file $param_other $param_config_game"
    $arg_str += "  -hidden -s main -s reloader"
    Start-Process -FilePath $conf["werl"] -ArgumentList $arg_str    
}

function fun_run ($conf,$inp) {
    switch ($inp) {
        "make" {
            fun_make $conf
            break
        }
        "start_game" {
            fun_start_game $conf
            break
        }
        Default {
            Write-Output "错误的命令"
        }
    }
    Set-Location $conf["cur_dir"]
}
function fun_wait_input ($conf) {
    $helpText = @"
==============================
make       	: 编译源码
start_game 	: 启动游戏服
quit       	: 结束运行
==============================  
"@
    Write-Output $helpText
    $inp = Read-Host "请选择"
    $inp = $inp.Trim().ToLower()
    switch ($inp) {
        ""      { 
            fun_wait_input $conf 
            break 
        }
        "quit"  {
            Set-Location $conf["cur_dir"] 
            break 
        }
        Default { 
            fun_run $conf $inp
            fun_wait_input $conf 
        }
    }
}

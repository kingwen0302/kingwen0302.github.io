@echo off
set FILE_DIR=%~dp0
RunHiddenConsole escript %FILE_DIR%/server_ctl_gui.erl --log_file %FILE_DIR%/server_ctl_gui.log --project_root E:/qqjy/qqjy_server/config

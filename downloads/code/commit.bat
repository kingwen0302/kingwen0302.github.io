@echo off

@set src_root_dir=%~dp0
@set dest_root_dir=e:\sgh5\server\trunk_commit
@set TortoiseProc=D:\TortoiseSVN\bin\TortoiseProc.exe

echo [1]svn update src ...
%TortoiseProc% /command:update /path:%src_root_dir%

echo [2]svn update dest ...
%TortoiseProc% /command:update /path:%dest_root_dir%

echo [3]meld ...
meld %src_root_dir% %dest_root_dir%

echo [4]compile ...
cd %dest_root_dir%
start xctl_commit.bat compile

cd %src_root_dir%
echo [5]commit ...
%TortoiseProc% /command:commit /path:%dest_root_dir%

echo [6]svn update src again ...
%TortoiseProc% /command:update /path:%src_root_dir%

echo [7]finish

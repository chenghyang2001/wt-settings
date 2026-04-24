@echo off
wt new-tab --title "wt-settings" -d "%USERPROFILE%\workspace\wt-settings" cmd /k claude --permission-mode bypassPermissions --continue -n "wt-settings"

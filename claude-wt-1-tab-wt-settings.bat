@echo off
wt -w new new-tab --title "wt-settings" --tabColor "#9933CC" -d "%USERPROFILE%\workspace\wt-settings" cmd /k claude --permission-mode bypassPermissions --continue -n "wt-settings"

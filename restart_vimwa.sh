#!/usr/bin/env bash
sshpass -pvs123ace ssh  quero@cameras-recepcao.lan sudo kill `ps aux | grep -v grep | grep vimwa_keep_running.sh | awk '{print $2}'`
sleep 3
sshpass -pvs123ace ssh  quero@cameras-recepcao.lan startx
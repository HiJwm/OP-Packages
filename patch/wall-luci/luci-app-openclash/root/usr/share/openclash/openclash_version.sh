#!/bin/bash
CKTIME=$(date "+%Y-%m-%d-%H")
LAST_OPVER="/tmp/openclash_last_version"
RELEASE_BRANCH=$(uci -q get openclash.config.release_branch || echo "master")
OP_CV=$(rm -f /var/lock/opkg.lock && opkg status luci-app-openclash 2>/dev/null |grep 'Version' |awk -F '-' '{print $1}' |awk -F 'Version: ' '{print $2}' |awk -F '.' '{print $2$3}' 2>/dev/null)
OP_LV=$(sed -n 1p $LAST_OPVER 2>/dev/null |awk -F '-' '{print $1}' |awk -F 'v' '{print $2}' |awk -F '.' '{print $2$3}' 2>/dev/null)
github_address_mod=$(uci -q get openclash.config.github_address_mod || echo 0)
LOG_FILE="/tmp/openclash.log"

if [ "$CKTIME" != "$(grep "CheckTime" $LAST_OPVER 2>/dev/null |awk -F ':' '{print $2}')" ]; then
	if [ "$github_address_mod" != "0" ]; then
      if [ "$github_address_mod" == "https://cdn.jsdelivr.net/" ]; then
         curl -SsL -m 10 https://cdn.jsdelivr.net/gh/vernesong/OpenClash@"$RELEASE_BRANCH"/version -o $LAST_OPVER 2>&1 | awk -v time="$(date "+%Y-%m-%d %H:%M:%S")" -v file="$LAST_OPVER" '{print time "【" file "】Download Failed:【"$0"】"}' >> "$LOG_FILE"
      elif [ "$github_address_mod" == "https://fastly.jsdelivr.net/" ]; then
         curl -SsL -m 10 https://fastly.jsdelivr.net/gh/vernesong/OpenClash@"$RELEASE_BRANCH"/version -o $LAST_OPVER 2>&1 | awk -v time="$(date "+%Y-%m-%d %H:%M:%S")" -v file="$LAST_OPVER" '{print time "【" file "】Download Failed:【"$0"】"}' >> "$LOG_FILE"
      elif [ "$github_address_mod" == "https://raw.fastgit.org/" ]; then
         curl -SsL -m 10 https://raw.fastgit.org/vernesong/OpenClash/"$RELEASE_BRANCH"/version -o $LAST_OPVER 2>&1 | awk -v time="$(date "+%Y-%m-%d %H:%M:%S")" -v file="$LAST_OPVER" '{print time "【" file "】Download Failed:【"$0"】"}' >> "$LOG_FILE"
      else
         curl -SsL -m 10 "$github_address_mod"https://raw.githubusercontent.com/vernesong/OpenClash/"$RELEASE_BRANCH"/version -o $LAST_OPVER 2>&1 | awk -v time="$(date "+%Y-%m-%d %H:%M:%S")" -v file="$LAST_OPVER" '{print time "【" file "】Download Failed:【"$0"】"}' >> "$LOG_FILE"
      fi
   else
      curl -SsL -m 10 https://raw.githubusercontent.com/vernesong/OpenClash/"$RELEASE_BRANCH"/version -o $LAST_OPVER 2>&1 | awk -v time="$(date "+%Y-%m-%d %H:%M:%S")" -v file="$LAST_OPVER" '{print time "【" file "】Download Failed:【"$0"】"}' >> "$LOG_FILE"
   fi

   if [ "${PIPESTATUS[0]}" -ne 0 ] || [ -n "$(cat $LAST_OPVER |grep '<html>')" ]; then
      curl -SsL -m 10 --retry 2 https://ftp.jaist.ac.jp/pub/sourceforge.jp/storage/g/o/op/openclash/"$RELEASE_BRANCH"/version -o $LAST_OPVER 2>&1 | awk -v time="$(date "+%Y-%m-%d %H:%M:%S")" -v file="$LAST_OPVER" '{print time "【" file "】Download Failed:【"$0"】"}' >> "$LOG_FILE"
      curl_status=${PIPESTATUS[0]}
   else
      curl_status=0
   fi

   if [ "$curl_status" -eq 0 ] && [ -z "$(cat $LAST_OPVER |grep '<html>')" ]; then
   	OP_LV=$(sed -n 1p $LAST_OPVER 2>/dev/null |awk -F '-' '{print $1}' |awk -F 'v' '{print $2}' |awk -F '.' '{print $2$3}' 2>/dev/null)
      if [ "$(expr "$OP_CV" \>= "$OP_LV")" -eq 1 ]; then
         sed -i "/^https:/i\CheckTime:${CKTIME}" "$LAST_OPVER" 2>/dev/null
         sed -i '/^https:/,$d' $LAST_OPVER
      elif [ "$(expr "$OP_LV" \> "$OP_CV")" -eq 1 ] && [ -n "$OP_LV" ]; then
         sed -i "/^https:/i\CheckTime:${CKTIME}" "$LAST_OPVER" 2>/dev/null
         exit 2
      fi
   else
      rm -rf "$LAST_OPVER"
   fi
elif [ "$(expr "$OP_CV" \>= "$OP_LV")" -eq 1 ]; then
   sed -i '/^CheckTime:/,$d' $LAST_OPVER
   echo "CheckTime:$CKTIME" >> $LAST_OPVER
elif [ "$(expr "$OP_LV" \> "$OP_CV")" -eq 1 ] && [ -n "$OP_LV" ]; then
   exit 2
fi 2>/dev/null

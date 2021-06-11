#!/usr/bin/env bash
# purpose: 
# the deployment script on ubuntu 20.04 - runs generically the deployment functions 
# starting with do_ from the src/bash/deploy/ubuntu/ubuntu-20.04.2-lts/*.func.sh files
# 

main(){
   do_set_vars "$@"  # is inside, unless --help flag is present
   ts=$(date "+%Y%m%d_%H%M%S")
   main_log_dir=~/var/log/$RUN_UNIT/; mkdir -p $main_log_dir
   main_exec "$@" \
    > >(tee $main_log_dir/$RUN_UNIT.$ts.out.log) \
    2> >(tee $main_log_dir/$RUN_UNIT.$ts.err.log)
}


main_exec(){
   do_set_fs_permissions
   do_deploy_min_req_bins
   do_load_functions

   test -z ${actions:-} || {
      do_run_actions "$actions"
   }
   do_finalize
   do_exit 0 "deploy ok"
}


#------------------------------------------------------------------------------
# the "reflection" func - identify the the funcs per file
#------------------------------------------------------------------------------
get_function_list () {
   env -i PATH=/bin:/usr/bin:/usr/local/bin bash --noprofile --norc -c '
      source "'"$1"'"
      typeset -f |
      grep '\''^[^{} ].* () $'\'' |
      awk "{print \$1}" |
      while read -r fnc_name; do
         type "$fnc_name" | head -n 1 | grep -q "is a function$" || continue
            echo "$fnc_name"
            done
            '
}


do_read_cmd_args() {
   
   img=$(lsb_release -d|grep -i ubuntu |perl -ne '$s=lc($_);$s=~s| |-|g;print $s'|awk '{print $2}')
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-a|--actions) shift && actions="${actions:-}${1:-} " && shift ;;
			-d|--database) shift && database="${database:-}${1:-} " && shift ;;
			-h|--help) actions=' do_print_usage ' && shift ;;
			*) echo FATAL unknown "cmd arg: '$1' - invalid cmd arg, probably a typo !!!" && shift && exit 1
    esac
  done
	shift $((OPTIND -1))

}


do_run_actions(){
   actions=$1
      cd $PRODUCT_DIR
      actions=$(echo -e "${actions}"|xargs)' '  #or how-to trim leading space
      run_funcs=''
      while read -d ' ' arg_action ; do
         while read -r fnc_file ; do
            #debug func fnc_file:$fnc_file
            while read -r fnc_name ; do
               #debug fnc_name:$fnc_name
               action_name=`echo $(basename $fnc_file)|sed -e 's/.func.sh//g'`
               action_name=`echo do_$action_name|sed -e 's/-/_/g'`
               #debug  action_name: $action_name
               test "$action_name" != "$arg_action" && continue
               source $fnc_file
               test "$action_name" == "$arg_action" && run_funcs="$(echo -e "${run_funcs}\n$fnc_name")"
               #debug run_funcs: $run_funcs ; sleep 3
            done< <(get_function_list "$fnc_file")
         done < <(find "src/bash/deploy/ubuntu/ubuntu-20.04.2-lts" -type f -name '*.func.sh'|sort)

      done < <(echo "$actions")
   run_funcs="$(echo -e "${run_funcs}"|sed -e 's/^[[:space:]]*//;/^$/d')"

   while read -r run_func ; do
      #debug run_funcs: $run_funcs ; sleep 3
      cd $PRODUCT_DIR
      do_log "INFO START ::: running action :: $run_func"
      $run_func
      exit_code=$?
      if [[ "$exit_code" != "0" ]]; then
         exit $exit_code
      fi
      do_log "INFO STOP ::: running function :: $run_func"
   done < <(echo "$run_funcs")

}


do_flush_screen(){
   printf "\033[2J";printf "\033[0;0H"
}


#------------------------------------------------------------------------------
# echo pass params and print them to a log file and terminal
# usage:
# do_log "INFO some info message"
# do_log "DEBUG some debug message"
#------------------------------------------------------------------------------
do_log(){
   type_of_msg=$(echo $*|cut -d" " -f1)
   msg="$(echo $*|cut -d" " -f2-)"
   log_dir="${PRODUCT_DIR:-}/data/log/bash" ; mkdir -p $log_dir \
      && log_file="$log_dir/${run_unit:-}.`date "+%Y%m"`.log"
   echo " [$type_of_msg] `date "+%Y-%m-%d %H:%M:%S %Z"` [${run_unit:-}][@${host_name:-}] [$$] $msg " \
      | tee -a $log_file
}


do_deploy_min_req_bins(){
	which perl 2> /dev/null || {
      sudo apt-get update
      sudo apt-get install -y perl
   }
	which jq 2> /dev/null || {
      sudo apt-get update
      sudo apt-get install -y jq
   }
}


do_set_vars(){
   set -u -o pipefail
	do_read_cmd_args "$@"
   export host_name="$(hostname -s)"
   unit_run_dir=$(perl -e 'use File::Basename; use Cwd "abs_path"; print dirname(abs_path(@ARGV[0]));' -- "$0")
   export RUN_UNIT=$(cd $unit_run_dir/../../../.. ; basename `pwd`)
   test -z ${TGT_PROJ:-} && export TGT_PROJ=$RUN_UNIT
   run_unit=$RUN_UNIT
   export PRODUCT_DIR=$(cd $unit_run_dir/../../../.. ; echo `pwd`)
   cd $PRODUCT_DIR

}


do_set_fs_permissions(){

   # Check if is running inside a container to ignore this function.
   test -f /.dockerenv && return 0

   chmod 700 $PRODUCT_DIR ; sudo chown -R ${USER:-}:${GROUP:-} $PRODUCT_DIR

   # User chmod rwx to source dirs.
   for dir in `echo lib src config`; do
      chmod -R 0700 $PRODUCT_DIR/$dir ;
   done  ;

   # User chmod rwx to sh and py files and rw- to all other files from source dirs.
   for dir in "$PRODUCT_DIR/config" "$PRODUCT_DIR/lib" "$PRODUCT_DIR/src"; do
      find $dir -type f -not -path */node_modules/* -not -path */venv/* \
         \( -name '*.*' ! -name '*.sh' ! -name '*.py' \) -exec chmod 600 {} \;
      find $dir -type f -not -path */node_modules/* -not -path */venv/* \
         \( -name '*.sh' -or -name '*.py' \) -exec chmod 700 {} \;
   done
}


do_finalize(){
   
   cat << EOF_INIT_MSG_NO_BOOT
   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
         $RUN_UNIT run completed 
   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
EOF_INIT_MSG_NO_BOOT
}



# ------------------------------------------------------------------------------
# clean and exit with passed status and message
# call by:
# do_exit 0 "ok msg"
# do_exit 1 "NOK msg"
# ------------------------------------------------------------------------------
do_exit(){
   exit_code=$1 ; shift
   exit_msg="$*"

   if (( ${exit_code:-} != 0 ));
   then
      exit_msg=" ERROR --- exit_code $exit_code --- exit_msg : $exit_msg"
      >&2 printf "$exit_msg"
      do_log "FATAL STOP FOR ${run_unit:-} deployer RUN with: "
      do_log "FATAL exit_code: $exit_code exit_msg: $exit_msg"
   else
      do_log "INFO STOP FOR ${run_unit:-} deployer RUN with: "
      do_log "INFO STOP FOR ${run_unit:-} deployer RUN: $exit_code $exit_msg"
   fi

   exit $exit_code
}


do_load_functions(){
    while read -r f; do source $f; done < <(ls -1 $PRODUCT_DIR/lib/bash/funcs/*.sh)
    while read -r f; do source $f; done < <(ls -1 $PRODUCT_DIR/src/bash/deploy/ubuntu/$img/*.func.sh)
 }

main "$@"

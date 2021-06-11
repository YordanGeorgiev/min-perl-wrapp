#------------------------------------------------------------------------------
# usage example:
# source $PRODUCT_DIR/lib/bash/funcs/flush-screen.sh
# do_flush_screen
#------------------------------------------------------------------------------
do_check_sudo(){
   printf "\nChecking sudo rights.\n\n"
   if sudo -n true 2>/dev/null; then
      printf "OK\n"
   else
      msg="sudo rights for user '$USER' do not exist !!! \n\n exiting ... \n\n\n"
      echo -e "$msg"
      exit 1
   fi
}

do_print_usage(){
   
   cat << EOF_USAGE
   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      This is a generic short bash funcs running script with logging
      PURPOSE:
      to run the src/bash/deploy/ubuntu/ubuntu-20.04.2-lts/*.func functions
      called "actions" generically
      example call: 
      ./deploy -a do_print_usage
   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

EOF_USAGE

   img=$(lsb_release -d|grep -i ubuntu |perl -ne '$s=lc($_);$s=~s| |-|g;print $s'|awk '{print $2}')

cat << EOF_US_02
   You can also execute one or multiple actions with the 
   $0 --action <<do_action_name>> 
   or 
   $0 -a <<do_action_name>> -a <<action_name-02>>

   where the <<action_name>> is one of the following
EOF_US_02
   find src/bash/deploy/ubuntu/ubuntu-20.04.2-lts/ -name *.func.sh \
      | perl -ne 's/(.*)(\/)(.*).func.sh/$3/g;print'| perl -ne 's/-/_/g;print "do_" . $_' | sort

   exit 1
}

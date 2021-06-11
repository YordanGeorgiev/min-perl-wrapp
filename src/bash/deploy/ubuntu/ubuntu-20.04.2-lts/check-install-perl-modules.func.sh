do_check_install_perl_modules(){

   cd $PRODUCT_DIR
   local_perl5dir=~/perl5
   bash_opts_file=~/.bashrc

   wget -O- http://cpanmin.us | perl - -l ~/perl5 App::cpanminus local::lib
   eval `perl -I ~/perl5/lib/perl5 -Mlocal::lib`
   echo 'eval `perl -I ~/perl5/lib/perl5 -Mlocal::lib`' >> ~/.bashrc
   echo 'export MANPATH=$HOME/perl5/man:$MANPATH' >> ~/.bashrc

   modules="$(cat ${BASH_SOURCE/.func.sh/.lst})"
   while read -r module ; do use_modules="${use_modules:-} use $module ; "; done < <(echo "$modules");

   perl -e "$use_modules" || {
      echo "deploying modules. This WILL at least 4 min, but ONLY ONCE !!!"
      test "$(grep -c 'Mlocal::lib' $bash_opts_file|xargs)" -eq 0 && \
         echo 'eval $(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)' >> $bash_opts_file
		while read -r module ; do cpanm_modules="${cpanm_modules:-} $module " ; done < <(echo "$modules")
		cmd="cpanm --local-lib=$local_perl5dir $modules"
      $cmd
      set +e
		}
}

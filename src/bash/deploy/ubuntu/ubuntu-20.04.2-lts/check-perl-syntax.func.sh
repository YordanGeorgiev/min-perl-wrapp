# file: src/bash/deploy/ubuntu/ubuntu-20.04.2-lts/check-perl-syntax.func.sh
do_check_perl_syntax(){

	find . -name autosplit.ix | xargs rm -fv # because idempotence
	declare -a ret; ret=0
   
   export PERL5LIB="$HOME"'/perl5/lib/perl5'
   # foreach perl file check the syntax by setting the correct INC dirs	
   cd $PRODUCT_DIR/src/perl/

   # run the autoloader utility	
   find . -name '*.pm' -exec perl -MAutoSplit -e 'autosplit($ARGV[0], $ARGV[1], 0, 1, 1)' {} \;
      c=0
      # feel free to adjust to 5, more might get you the "Out of memory!" error
      amount_of_perl_syntax_checks_to_run_in_parallel=1
      while read -r file ; do 
         c=$((c+1)) ; test $c -eq $amount_of_perl_syntax_checks_to_run_in_parallel && sleep 1 && export c=0 ;
         (
            #echo -e "::: running: cd src/perl/; perl -MCarp::Always -I `pwd` -I `pwd`/lib -wc \"$file\" ; cd -"
            perl -MCarp::Always -I `pwd` -I `pwd`/lib -wc "$file"
         )&
      done < <(find "." -type f \( -name "*.pl" -or -name "*.pm" -or -name '*.t' \))
      test $ret -ne 0 && break ; 
   
      cd $PRODUCT_DIR ; 


	test $ret -ne 0 && echo "FATAL Perl syntax error" && exit 1;
	
	do_flush_screen
}

#eof file: src/bash/deploy/ubuntu/ubuntu-20.04.2-lts/check-perl-syntax.func.sh

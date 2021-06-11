#!/usr/bin/env perl

use strict;
use warnings qw< FATAL  utf8     >;
#use autodie qw(:all);
use utf8;
use open qw< :std  :utf8     >;
use charnames qw< :full >;
use feature qw< unicode_strings >;
use 5.28.0;
use lib $ENV{'HOME'} . '/perl5/lib/perl5' ;
require Exporter;
our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ('all' => [qw()]);
our @EXPORT_OK   = (@{$EXPORT_TAGS{'all'}});
our @EXPORT      = qw($config);
our $AUTOLOAD    = ();

$| = 1;

our $ProductDir = '' ;

BEGIN {
  use Cwd qw (abs_path);
  my $my_inc_path = Cwd::abs_path($0);
  $my_inc_path =~ m/^(.*)(\\|\/)(.*?)(\\|\/)(.*)/;
  $my_inc_path = "$1/lib" ; 

  unless (grep { $_ eq "$my_inc_path" } @INC) {
    push(@INC, "$my_inc_path");
    $ENV{'PERL5LIB'} .= "$my_inc_path";
  }

  # print join(", ", @INC);
  # kprint "EOF \@INC";
}

END { close STDOUT }

use Cwd qw ( abs_path );
use File::Basename qw< basename >;
use Carp qw< carp croak confess cluck >;
use Encode qw< encode decode >;
use Unicode::Normalize qw< NFD NFC >;
use Data::Printer;
use Log::Handler ;

# use own modules ...
use Qto::App::Utils::Initiator;
use Qto::App::Utils::Timer;
use Qto::App::IO::In::RdrXls ;
use Qto::App::IO::Out::WtrFiles ; 

# give a full stack dump on any untrapped exceptions
local $SIG{__DIE__} = sub {
  $0 = basename($0);    # shorter messages
  confess "\n\n\n FATAL Uncaught exception: @_" unless $^S;
};

# now promote run-time warnings into stackdumped exceptions
#   *unless* we're in an try block, in which
#   case just generate a clucking stackdump instead
local $SIG{__WARN__} = sub {
  $0 = basename($0);    # shorter messages
  if   ($^S) { cluck "\n\n WARN Trapped warning: @_" }
  else       { cluck "\n\n WARN Deadly ?! warning: @_" }
};


our $config             = {};
our $objModel           = {};
our $objLogger          = {};
my $module_trace        = 0;
my $md_file             = '';
my $objInitiator        = {};
my $objConfigurator     = {};
my $xls_dir             = q{};
my $xls_file            = q{};
my $qto_project         = q{};
my $period              = q{};
my $tables              = 'daily' ;


#
# the main shell entry point of the application
sub main {

  my $msg = 'error during initialization of the tool !!! ';
  my $ret = 1;

  print " qto.pl START  \n ";
  ($ret, $msg) = do_init();
  doExit($ret, $msg) unless ($ret == 0);
  my @tables = ('integrations');
  $ProductDir = $config -> {'env'}->{'run'}->{'ProductDir'} ; 
  my $xls_file = $ProductDir . '/dat/xls/in/in.xlsx' ;
  my $objRdrXls    = 'Qto::App::IO::In::RdrXls'->new ( \$config , \@tables ) ;
  ($ret, $msg , my $hsr3 ) = $objRdrXls->doReadXlsFileToHsr3 ( $xls_file ) ; 
  my $hs_integrations = $hsr3->{'integrations'} ; 
  p ($hs_integrations);
  my $whole_graph_str = 'graph g { node [ fontname=Arial, fontcolor=blue, fontsize=9];' . "\n";
  my $nodes_def_str = 'node0 [label="PETS"]' . "\n" ;
  my $nodes_con_str = '' ;
  foreach my $rowid ( keys %$hs_integrations) {
      next if $rowid eq "0" ; 
      print "\$rowid: $rowid \n" ; 
      my $label_val = $hs_integrations->{$rowid}->{'outgoing_interface'} ; 
      next if ( $label_val eq '-' or $label_val eq 'NULL' or $label_val eq '' );
      $nodes_def_str .= 'node' . $rowid . '[label="' . $hs_integrations->{$rowid}->{'outgoing_interface'} . '"]' . "\n" ;
      $nodes_con_str .= 'node0 -- ' . 'node' . $rowid . "\n"; 
      foreach my $header ( keys %{$hs_integrations->{ "$rowid" }}) {
         print "\$header: " . $header . "\n" ; 
         print "\$val: " . $hs_integrations->{$rowid}->{$header} . "\n" ; 
      }
  }
  $whole_graph_str .= $nodes_def_str ; 
  $whole_graph_str .= $nodes_con_str ; 
  $whole_graph_str .= "\n" . '}';
  my $objWtrFiles   = 'Qto::App::IO::Out::WtrFiles'->new() ; 
  $objWtrFiles->doPrintToFile ( "$ProductDir/dat/out/out.txt" , $whole_graph_str, 'utf8' ) ;
  print $whole_graph_str ; 
#graph g {
#	node0 [label="center"]
#	node1 [label="foo"]
#	node2 [label="bar"]
#	node3 [label="baz"]
#
#	node0 -- node1
#	node0 -- node2
#	node0 -- node3
#}


  doExit($ret, $msg);

}



sub do_init {

   my $msg          = 'error during initialization !!!';
   my $ret          = 1;
   $objInitiator    = 'Qto::App::Utils::Initiator'->new();
   $config          = $objInitiator->get('AppConfig');

   $config->{'env'}->{'run'}->{'ProductDir'} = $objInitiator->doResolveProductDir();
   $config->{'env'}->{'run'}->{'ProductName'} = $objInitiator->doResolveProductName();
   $config->{'env'}->{'run'}->{'VERSION'} = $objInitiator->doResolveVersion();
   $config->{'env'}->{'run'}->{'ENV_TYPE'} = $objInitiator->doResolveEnvType();

   p $config ; # not a debug print !!!
   sleep 1 ; 

   $objLogger = Log::Handler->new;
   my $m = "START MAIN";
   $objLogger->info($m);

   $ret = 0;
   return ($ret, $msg);
}



#
# pass the exit msg and the exit to the calling process
#
sub doExit {

  my $exit_code = shift;
  my $exit_msg = shift || 'exit qto.pl';

  if ($exit_code == 0) {
    $objLogger->info($exit_msg);
  }
  else {
    $objLogger->error($exit_msg);
  }

  my $msg = "STOP MAIN";
  exit($exit_code);
}


main();

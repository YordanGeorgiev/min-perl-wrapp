package Qto::App::Utils::Initiator ; 

	use strict; use warnings;

	my $VERSION = '1.3.1';    #doc at the end

	require Exporter;
	our @ISA = qw(Exporter Qto::App::Utils::OO::SetGetable Qto::App::Utils::OO::AutoLoadable) ;
	our $AUTOLOAD =();
	our $ModuleDebug = 0 ; 
	use AutoLoader;

	use Cwd qw/abs_path/;
   use File::Basename;
	use File::Path qw(make_path) ;
	use File::Find ; 
	use File::Copy;
	use File::Copy::Recursive ; 
   use Data::Printer ; 
	use Carp qw /cluck confess shortmess croak carp/ ; 

   use parent 'Qto::App::Utils::OO::SetGetable' ;
   use parent 'Qto::App::Utils::OO::AutoLoadable' ;

	our $config						   = {} ; 
   our $rel_levels               = 0 ; 
   our $my_absolute_path         = '' ; 
=head1 SYNOPSIS

	doResolves the product version and base dirs , bootstraps config files if needed

		 use Initiator;
		 my $objInitiator = new Initiator () ; 

	=head1 EXPORT

	A list of functions that can be exported.  You can delete this section
	if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS


=cut

	#
	# ---------------------------------------------------------
	# the product base dir is the dir under which all the product
	# instances are installed 
	# ---------------------------------------------------------
	sub doResolveProductBaseDir {

		my $self = shift;
		my $msg  = ();
		my $levels_up = 8 + $rel_levels ; 
		my $product_base_dir = '' ; 
		my @DirParts = ();
		@DirParts = @{doGetDirParts($levels_up)};
      $product_base_dir = join( '/', @DirParts );
		my $ProductBaseDir 						= $product_base_dir ; 
		$self->{'ProductBaseDir'} 			= $ProductBaseDir ; 
		$config->{'ProductBaseDir'} 	   = $ProductBaseDir ; 
		$self->{'AppConfig'} 				= $config; 

		return $ProductBaseDir;
	}
	

	#
	# ---------------------------------------------------------
	# the product base dir is the dir under which all the product
	# instances are installed 
	# ---------------------------------------------------------
	sub doGetDirParts {

		my $msg  = ();
		my $levels_up = shift ; 

      $my_absolute_path = abs_path( __FILE__ ); 
      
		$my_absolute_path =~ tr|\\|/| if ( $^O eq 'MSWin32' );
		my @DirParts = split( '/' , $my_absolute_path );
		for ( my $count = 0; $count < $levels_up ; $count++ ){ 
			pop @DirParts; 
		}
		
		return \@DirParts ; 
	}

	#
	# ---------------------------------------------------------
	# the product version dir is the dir where this product 
	# instance is situated
	# ---------------------------------------------------------
	sub doResolveProductDir {

		my $self = shift;
      $rel_levels = shift unless ( $rel_levels ) ; 
      $rel_levels = 0 unless $rel_levels ; 
		my $msg  = ();
		my $levels_up = 7 + $rel_levels ; 
		my @DirParts = @{doGetDirParts ( $levels_up )} ; 
		my $ProductDir             = join( '/' , @DirParts );

		$self->{'ProductDir'} 	   = $ProductDir ; 
		$config->{'ProductDir'} 	= $ProductDir ; 
		$self->{'AppConfig'} 	   = $config; 

		return $ProductDir;
	}

   sub doResolveVersion {
		my $self = shift ; 

      my $ProductDir = $self->doResolveProductDir() ; 
		my $file = $ProductDir . '/.env' ;
      my $ProductVersion = {} ; 

      carp "no .env file $file in the product instance dir !!!" unless -f $file ; 
		open my $fh, '<', $file ; 
		
		while( my $line = <$fh>)  {   
			 $ProductVersion = $line;    
			 $ProductVersion =~ s/VERSION=(.*)$/$1/g;
          chomp($ProductVersion);
			 last if $ProductVersion =~ m/\d.\d.\d/g ;
		}
		close $fh; 
		$self->{'VERSION'} 	   = $ProductVersion;
		$config->{'VERSION'} 	= $ProductVersion; 
		$self->{'AppConfig'}    = $config; 

      return $ProductVersion;
   }
   
   sub doResolveEnvType {
		my $self = shift ; 

      my $ProductDir = $self->doResolveProductDir() ;
      my $EnvType = '' ;
		my $file = $ProductDir . '/.env' ;
      carp "no .env file $file in the product instance dir !!!" unless -f $file ; 
		open my $fh, '<', $file  ; 
		
		while( my $line = <$fh>){
         next unless $line =~ m/ENV_TYPE/;

			$EnvType = $line;    
			$EnvType =~ s/ENV_TYPE=(.*)$/$1/g;
			last if $EnvType =~ m/|dev|tst|stg|qas|prd|/g ;
		}
		close $fh; 
      chomp($EnvType);
		$self->{'EnvType'} 	   = $EnvType;
		$config->{'EnvType'} 	= $EnvType; 
		$self->{'AppConfig'}    = $config; 

      return $EnvType;
   }


	#
	# ---------------------------------------------------------
	# the Product name is the name by which this Product is 
	# identified 
	# ---------------------------------------------------------
	sub doResolveProductName {

		my $self = shift;
		my $msg  = ();

      my $ProductDir = $self->doResolveProductDir() ; 
		my $ProductName = $ProductDir ; 
		$ProductName =~ s/^(.*)[\/|\\](.*)/$2/g ; 

		$config->{ 'ProductName' } 		= $ProductName ; 
		$self->{'AppConfig'} 				= $config; 
		return $ProductName;
	}









	sub new {
		
		my $invocant = shift;    
		my $class = ref ( $invocant ) || $invocant ; 
      $rel_levels = shift || 0 ; 

		my $self = {};        # Anonymous hash reference holds instance attributes
		bless( $self, $class );    # Say: $self is a $class

      # !!! important concept - src: https://stackoverflow.com/a/90721/65706
		my $ProductBaseDir 			      = $self->doResolveProductBaseDir();
	   my	$ProductDir 			         = $self->doResolveProductDir();
		my $ProductName 				      = $self->doResolveProductName();
		my $EnvType 				         = $self->doResolveEnvType();
		my $ProductVersion 			      = $self->doResolveVersion();
		return $self;
	}  


	# -----------------------------------------------------------------------------
	# cleans potentially suspicious dirs and files for the perl -T call
	# -----------------------------------------------------------------------------
	


1;

__END__

=head1 NAME

Initiator 

=head1 SYNOPSIS

use Initiator  ; 


=head1 DESCRIPTION
get the absolute paths of the application during run-time

=head2 EXPORT


=head1 SEE ALSO

perldoc perlvars

No mailing list for this module


=head1 AUTHOR

ext-yordan.georgiev@posti.com

=head1 




=cut 


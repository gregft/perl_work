#!/usr/bin/perl

use Getopt::Std;

#
# This script generates InstallAnywhere manifest from a directory.
#
# Usage:
#
# generate_manifest.pl [-h] [-c] [-p] <Resource Path IA variable> <Manifest file> <Release tree>
#

getopts("hcp");

if ( $opt_h )
{
	usage();
	exit 0;
}

if ( 3 < $#ARGV )
{
	print "Invalid number of arguments.\n";
	usage();
	exit 1;
}

$iaVar = shift @ARGV;
$manifestFile = shift @ARGV;
$reldir = shift @ARGV;

if ( "$iaVar" ne "SYBASE" && "$iaVar" ne "SYBASE_GENERIC" &&
		"$iaVar" ne "SYBASE_UNIX" && "$iaVar" ne "SYBASE_WIN" )
{
	print "IA variable must be SYBASE, SYBASE_GENERIC, SYBASE_UNIX, or SYBASE_WIN.\n";
	exit 1;
}

if ( ! ( -d $reldir || -l $reldir ) )
{
	print "$reldir directory does not exist.\n";
	exit 1;
}


# Check manifest
if ( $opt_c )
{
	$line = 0;
	open(MANIFEST, "$manifestFile") or die "Can not read manifest file $manifestFile.\n";
	while(<MANIFEST>)
	{
		$line++;

		$_ = trim($_);
		next if $_ eq "";
		next if $_ =~ /^#/;

		@tmp = split(/,/);

		if ( $#tmp != 3 || $tmp[0] !~ /F/ || $tmp[3] > 777 )
		{
			print "ERROR: Invalid format in line $line.\n";
			next;
		}

		$tgtFile = $tmp[1];

		@tmp2 = split(/\$/, $tgtFile);
		if ( $iaVar !~ /$tmp2[1]/ )
		{
			print "WARNING: $tgtFile - Not using IA variable name $iaVar.\n";
			next;
		}

		$subTgtFile = $tgtFile;
		$subTgtFile =~ s/\$$iaVar\$/$reldir/;
		if  ( ! -f $subTgtFile )
		{
			print "ERROR: $tgtFile - Not exist in release tree.\n";
			next;
		}

		if ( $opt_p )
		{
			$filePerm = &convertPer2Mode($tmp[3]);
			$defaultFilePerm = &getFileDefaultPermission($subTgtFile);
			if ( $filePerm != $defaultFilePerm )
			{
				print "WARNING: $tgtFile - Not appear to have correct permission.\n";
			}
		}
	}
}
# Generate manifest
else
{
	open(MANIFEST, "> $manifestFile") or die "Can not open manifest file $manifestFile.\n";
	chdir("$reldir");
	`find . -exec ls -d {} \\; > /tmp/gen.$$`;

	open(FILE, "/tmp/gen.$$");
	while(<FILE>)
	{
		chop;
		$fileName = substr($_, 2);
		next if ! $fileName;
		@tmp = split(/ /, `ls -ld '$fileName'`);
		if ($tmp[0] =~ /^d/)
		{
			#
			# When specified directory in manifest file, IA takes everything
			# under the directory.  Since we are looping through all the files,
			# this is not needed.
			#
			# $fileType = "D";
		}
		elsif ($tmp[0] =~ /^G/)
		{
			#
			# Manifest file does not support symbolic link
			#
			# $fileType = "L";
			print "WARNING: $fileName is a symbolic link.\n";
			print "	Manifest file does not support symbolic link.\n";
			print "	Please contact SybInstall installer developer on how to add symbolic link in the installer.\n";
		}
		else
		{
			if ( $opt_p )
			{
				$filePerm = &getFileDefaultPermission($fileName);
			}
			else
			{
				$filePerm = &convertPer2Mode($tmp[0]);
				$defaultFilePerm = &getFileDefaultPermission($fileName);
				if ( $filePerm != $defaultFilePerm )
				{
					#print "WARNING: $fileName doesn't appear to have correct permission.$defaultFilePerm \n";
				}

				# Add owner write permission.  This is a requirement for IA installer.
				if ( (int($filePerm / 100) & 2) != 2 )
				{
					$filePerm = $filePerm + 200;
				}

				# Add owner read permission.  This is a requirement for IA installer.
				if ( (int($filePerm / 100) & 4) != 4 )
				{
					$filePerm = $filePerm + 400;
				}
			}
			$fileType = "F";
			print MANIFEST "$fileType,\$$iaVar\$/$fileName,./$fileName,$filePerm\n";
		}
	}
	close FILE;
	unlink "/tmp/gen.$$";

	if ( $opt_p )
	{
		print "The file permissions written to the manifest are based on the file type.  Please review they are correct.\n";
	}
}
close MANIFEST;

############################################################
# getFileDefaultPermission()
#       argument: Get the file default permission.
#
# Return the octal number file permission base on the file type.
#	executable and libraries return 755
#	other file types return 644
############################################################
sub getFileDefaultPermission()
{
	my ($fileName) = @_;
	my ($output) = `file $fileName`;

	# Executables
	if ( $output =~ /executable/o  && ! ( $output =~ /archive/o ) )
	{
		return 755;
	}
	# Shared library
	elsif ( ( $output =~ /dynamic lib/o ||
			$output =~ /shared object/o )
			&& ! ( $output =~ /archive/o ) )
	{
		return 755;
	}
	# archives files
	elsif ( $output =~ /archive/o )
	{
		return 755;
		#return 644;
	}
	# Known binary files that don't need exec permission.
	elsif ( $fileName =~ /\.jar$/o ||
			$fileName =~ /\.zip$/o || 
			$fileName =~ /\.ico$/o || 
			$fileName =~ /\.bmp$/o || 
			$fileName =~ /\.jpg$/o || 
			$fileName =~ /\.jpeg$/o || 
			$fileName =~ /\.xlt$/o || 
			$fileName =~ /\.uct$/o ||
			$fileName =~ /\.ust$/o ||
			$fileName =~ /\.dat$/o ||
			$fileName =~ /\.lcu$/o ||
			$fileName =~ /\.png$/o ||
			$fileName =~ /\.gif$/o )
	{
		return 644;
	}
	# Binary file
	elsif ( -B $fileName )
	{
		return 755;
	}
	# Text file
	elsif ( -T $fileName )
	{
		return 644;
	}

	# Unknown file type, return 755.
	return 755;
}

############################################################
# convertPer2Mode()
#       argument: permission
#
# Convert rwx permission to octal numbers.
############################################################
sub convertPer2Mode()
{
        my (@chars, $mode, $i);
        my ($p) = @_;
        $p = substr($p, 1);
        @chars = split(//, $p);
        $mode = 0;

        for($i=0; $i<3; $i++)
        {
                if ($chars[$i] eq 'r')
                {
                        $mode = $mode + 400;
                }
                elsif ($chars[$i] eq 'w')
                {
                        $mode = $mode + 200;
                }
                elsif ($chars[$i] eq 'x')
                {
                        $mode = $mode + 100;
                }
        }

        for($i=3; $i<6; $i++)
        {
                if ($chars[$i] eq 'r')
                {
                        $mode = $mode + 40;
                }
                elsif ($chars[$i] eq 'w')
                {
                        $mode = $mode + 20;
                }
                elsif ($chars[$i] eq 'x')
                {
                        $mode = $mode + 10;
                }
        }

        for($i=6; $i<9; $i++)
        {
                if ($chars[$i] eq 'r')
                {
                        $mode = $mode + 4;
                }
                elsif ($chars[$i] eq 'w')
                {
                        $mode = $mode + 2;
                }
                elsif ($chars[$i] eq 'x')
                {
                        $mode = $mode + 1;
                }
        }

        return $mode;
}


############################################################
# trim()
#	arguments: <string>
#
# Trim the leading and trailing space characters in a string
############################################################
sub trim
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

############################################################
# usage()
#       arguments: none
#
# Show this script usage.
############################################################
sub usage()
{
	print "This script generates InstallAnywhere manifest file from a directory.\n\n";
	print "Usage: generate_manifest.pl [-h] [-c] [-p] <Resource Path IA variable> <Manifest file> <Release tree>\n\n";
	print "where:\n";
	print "	[-h] Print this usage\n";
	print "	[-c] Check manifest is correct and files exist in drop/release tree\n";
	print "	[-p] Set file permissions to 755 or 644 base on the file type.\n";
	print "		If uses with -c argument, check permissions in\n";
	print "		manifest matches the file type.\n";
	print "	<Resource Path IA variable> IA variable name write to manifest.\n";
	print "		Valid values: SYBASE, SYBASE_GENERIC, SYBASE_UNIX, or SYBASE_WIN\n";
	print "	<Manifest file> Manifest file to create or check.\n";
	print "	<Release tree> Drop or \$SYBASE directory to get the file list\n\n";
	print "NOTE: When -p argument is specified, the file permissions written to\n";
	print "	the manifest are from best guessing the file type.  Some may not be correct.\n";
	print "	You need to review the manifest after it is generated.\n";
}

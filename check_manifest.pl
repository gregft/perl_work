#!/usr/bin/perl
#use warnings;

sub fnDebugPrint
  {
  print "$_[0]";
  }

sub fnDetailedDebug
  {
 #fnDebugPrint("LineType=$LineType\n");
  }

# quit unless we have the correct number of command-line args
$num_args = $#ARGV + 1;
#print "\n Args passed in: $num_args \n";

if ($num_args < 1) {
  print "\nUsage: checkManifest.pl manifest-file \n";
  exit -1;
}  else {
  $OrigFilename=$ARGV[0];
}
$SOURCE_PATH=$ARGV[1];

open(OrigDATA,"<$OrigFilename") or die "Can't open file $OrigFilename";

@lines_Orig = <OrigDATA>;

# Gets the Size of the Array
$iSizeOfArrayOrig = @lines_Orig;   
#print "Size of the array is $iSizeOfArrayOrig \n";


while ($count < $iSizeOfArrayOrig) {
 
$FirstChar=substr $lines_Orig[$count],0,1;
#$LastChar=substr $lines_Orig[$count],-2,1;
#print "FirstChar=$FirstChar  LastChar=$LastChar \n";
@CommaDelimited_Orig = split (/,/,  $lines_Orig[$count]);

#Check to make sure first line is not commented out
if ( $FirstChar eq "F" )
{
   #  print "CommaDelimited_Orig[0] = $CommaDelimited_Orig[0] \n"; 
   #  print "CommaDelimited_Orig[1] = $CommaDelimited_Orig[1] \n"; 
   $SOURCE=substr $CommaDelimited_Orig[1],8,991;
   $CommaDelimited_Orig[2] =~ s/^\s+|\s+$//g;
   $TARGET=substr $CommaDelimited_Orig[2],1,991;
   chomp($SOURCE);
   #$TARGET =~ s/^\s+|\s+$//g;
	if ($SOURCE ne $TARGET)
 	{

@SlashDelimited_TARGET = split (/\//,  $TARGET);
@SlashDelimited_SOURCE = split (/\//,  $SOURCE);
$iSizeOfArraySlashDelimited_TARGET = @SlashDelimited_TARGET;
$iSizeOfArraySlashDelimited_SOURCE = @SlashDelimited_SOURCE;

#print " File= $SlashDelimited_TARGET[$iSizeOfArraySlashDelimited_TARGET-1] \n";
#print " File= $SlashDelimited_SOURCE[$iSizeOfArraySlashDelimited_SOURCE-1] \n";
 $TARGET_FILE = $SlashDelimited_TARGET[$iSizeOfArraySlashDelimited_TARGET-1];
 $SOURCE_FILE = $SlashDelimited_SOURCE[$iSizeOfArraySlashDelimited_SOURCE-1];
	 

	if ($SOURCE_FILE ne $TARGET_FILE)
        {
	  print "SOURCE = $SOURCE \n";
	  print "TARGET = $TARGET \n"; 
 	  print " ERROR: $OrigFilename  $SOURCE_FILE Not EQ $TARGET_FILE \n";
	  fnDebugPrint("---------------------------- \n"); 
	 }
	}
    $FULL_SOURCE_FILE = "$SOURCE_PATH/$SOURCE";
    if  ( ! -e $FULL_SOURCE_FILE )
    {
         print "ERROR:  $OrigFilename $FULL_SOURCE_FILE - Not exist in release tree.\n";
    }
	#print "$SOURCE_PATH/$SOURCE \n";
}     
  $count++;

#

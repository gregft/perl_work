#!/usr/bin/perl
#
#	@(#)	generic/msgdb/sh_scripts/convert_percent	1.5	5/23/95
#
#	This is a perl script to change the placeholders in server.loc 
# 	for translation into other languages.
#
#	02/10/96 (dkh) - Addded new constructs to handle double percent
#			 signs by changing them to "GPG.pid" before
#			 substitutions.  Then changing them back after
#			 checking for unconverted percents.
#	02/10/96 (dkh) - Changed error message to output the message
#			 number rather than line number.
#	02/10/96 (dkh) - Special cased sql server message number 13074
#			 so that it is not reported as an error if the
#			 only unconverted percent is at the end of the message.
#	12/16/97 (dkh) - Added support for handling rep server messages.
#	09/11/98 (dkh) - Added handling for %lu.
#	09/11/98 (dkh) - Added support for latest set of rep serve tokens.
#	09/11/98 (dkh) - Added missing quote in front of RS_QID.
#	05/21/99 (dkh) - Added support for %#X.
#	06/11/99 (dkh) - Added support for RS_DTID.
#	03/30/01 (dkh) - Added support for 5d.
#	02/16/02 (scanon) - Added support for RS_SYNC_MODEL and RS_LOCK_TYPE.
#	04/01/04 (dkh) - Added support for S_PTNINFO.
#   08/04/14 (lll) - Added support for RS_CMD 

@percent_tags =
( "c", "f", "x", "0x", "X", "lx", "ld", "u", "lu", "\\.0lf", "04x", "08lx", "s", "\\.s", "\\*s",  "\\.\\*s", "\\*\\.s", "d", "\\*\\.d", "\\.\\*x", "#X", "p", "S_OBJID", "S_MSG", "S_DBID", "S_BUF", "S_DATE", "S_RID", "S_SRVID", "S_BLKIOPTR", "S_PAGE", "S_DES", "S_SDES", "S_DBT", "S_KEY", "S_NUME", "S_REPAGNT", "S_EED", "\\.S_DBID", "LTM_CMD", "LTM_TRUNC_PT", "RS_DTID", "RS_KEY", "RS_LOCATOR", "RS_OBJECT", "RS_MSG", "RS_TIME", "RS_CLIENT", "RS_CLIENTMSG", "RS_CLIENT_SHORT", "RS_SERVERMSG", "RS_SRVERR", "RS_MEMHDR", "RS_RSID", "RS_SQM_INFO", "RS_SITEID", "RS_QID", "RS_Q_ID", "RS_HANDLE", "RS_MONEY", "RS_SQ_LOC_Q_ID", "RS_SQM_TRAN", "RS_REP_OBJECT", "RS_Q_NAME", "RS_SQT_TRAN_STATE", "RS_SQT_STATE", "RS_Q__NAME", "RS_XACTID", "RSID", "RS_SYNC_MODEL", "RS_LOCK_TYPE", "5d", "S_PTNINFO", "RS_SIZE_T", "RS_DS_MAKE", "RS_CONN_TYPE", "RS_CMD");

$regex = "(%".join(")|(%",@percent_tags).")";
$doublepercent = "GPG.$$";

$backslash = 0;
while(<>)
{
	if ($baskslash || (/\d*\s*=\s*[\S]*,\s*".*/))
	{
		s/%%/$doublepercent/ego;
		if (! $backslash)
		{
			$cnt = 1;
			/^(\d*)/;
			$msgnum = "$&";
		}
#		$cnt = 1 unless $backslash;
		s/$regex/'%'.$cnt++.'!'/ego;
		$backslash = 0; $backslash = 1 if /\\$/;
		if (/%[^\d]/)
		{
			if ($msgnum ne "13074" || $' ne "\n" || $& ne "%\"")
			{
				print STDERR "Message $msgnum: Some percents not converted in this line.\n";
			}
		}
#		print STDERR "Message $msgnum: Some percents not converted in this line.\n" if /%[^\d]/;
		s/$doublepercent/'%%'/ego;
	}
	print ;
}

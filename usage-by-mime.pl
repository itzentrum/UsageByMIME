#!/usr/bin/env perl
use strict;
use warnings;

our @filelist;
our %usage_mime_full;
our %usage_mime_base;
our $cur_file_ct=0;

$SIG{"USR1"} = sub {
    print "\nAt File no $cur_file_ct\n"; 
    };

sub quote 
{
    my $str=pop;
    $str =~ s/(["' ()\$&])/\\$1/g;
    return $str;
}
sub scan_dir
{
    my $dir = pop;
    my $dh;
    opendir($dh, $dir) || die "can't opendir $dir: $!";
    while(my $entry = readdir $dh) {
	if (!($entry eq "." || $entry eq ".."))
	{
	    my $quoted_path=quote "$dir/$entry";
#	    print "$quoted_path\n";
	    scan_dir($quoted_path) if (-d $quoted_path);
	    push @filelist, $quoted_path;
	}
    }
    closedir $dh;

}

sub work_file_list
{
    my $filecount=scalar(@filelist);
#    print "Got $filecount files\n";
    my $percent=0;
    my $oldpercent=0;
    print $percent;
    for ($cur_file_ct=0;$cur_file_ct<$filecount;$cur_file_ct++) 
    {
	$percent=int($cur_file_ct/$filecount*100);
	if ($percent != $oldpercent and $percent % 10 == 0)
	{
	    $oldpercent=$percent;
	    print " ... $percent";
	}
	my $type_str=`file --mime-type -b $filelist[$cur_file_ct]`;
	if ($type_str=~/^(.*)\/(.*)$/)
	{
	    my $mime_base="$1";
	    my $mime_sub="$2";
	    my $filesize=(-s $filelist[$cur_file_ct] or 0);
	    $usage_mime_full{"$mime_base/$mime_sub"}+=$filesize/1048576;
	    $usage_mime_base{"$mime_base"}+=$filesize/1048576;
	}
	else
	{
	    print "\nTYPE ERROR: $filelist[$cur_file_ct] -> $type_str\n";
	}
    }
    print " ... 100\n";
}
my $dirname=$ARGV[0];
print "Creating directory file list\n";
scan_dir($dirname);
print "Got ".scalar(@filelist)." files\n";
print "Scanning file list\n";
work_file_list;
print "Basic MIME Types:\n";
foreach my $key (sort {$usage_mime_base{$b} <=> $usage_mime_base{$a} } keys %usage_mime_base)
{
    printf("%.2f MB\t%s\n",$usage_mime_base{$key},$key);
}
print "Full MIME Types:\n";
foreach my $key (sort {$usage_mime_full{$b} <=> $usage_mime_full{$a} } keys %usage_mime_full)
{
    printf("%.2f MB\t%s\n",$usage_mime_full{$key},$key);
}

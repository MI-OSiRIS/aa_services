#!/usr/bin/env perl

#
# os2ns.pl - OpenLDAP Schema to Netscape Schema converter and concatinator
#
# (c) 2017 Wayne State University
#

use IO::Prompt;

unless ($ARGV[1]) {
    die "Usage: os2ns.pl <infile> <infile2> <infile..N> <outfile>\n";
}

my $outfile = $ARGV[$#ARGV];
my @files = @ARGV[0..$#ARGV-1];

if (-e $outfile) {
    unless (prompt("The file '$outfile' already exists, overwrite? [y/N] ", -yn1td=>"n")) {
        die "User aborted.\n";
    }
}

open my $ofh, '>', $outfile or die "Can't write to $outfile - $!\n";

print $ofh "dn: cn=schema\n";
print $ofh "objectClass: top\n";
print $ofh "objectClass: ldapSubentry\n";
print $ofh "objectClass: subschema\n";
print $ofh "cn: schema\n";

my $ifh, $pdepth;
foreach my $file (@files) {
    open $ifh, '<', $file or die "Can't read from $file - $!\n";
    while (my $line = <$ifh>) {
        # any whitespace at the end of any line was just a newline.  plain and simple.
        $line =~ s/[\s\r\n]+$/\n/;
        
        if ($line =~ /^#/) {
            print $ofh $line;
        } elsif ($line =~ /^(attributeType)[\s\(\n]+/i) {
            $line =~ s/$1/attributeTypes:/;
            print $ofh $line;
        } elsif ($line =~ /(objectClass)[\s\(\n]+/i) {
            $line =~ s/$1/objectClasses:/;
            print $ofh $line;
        } elsif ($line =~ /^\s*$/) {
            # no empty lines in LDIF, replace with comment lines.
            print $ofh "#\n";    
        } elsif ($line =~ /^[\w\(\)\']+/) {
            # continuations need whitespace at the beginning
            print $ofh " " . $line;
        } else {
            # let's peek ahead to see if there's a lonesome paren on the next line..
            my $pos = tell($ifh);
            my $next_line = <$ifh>;
            if ($next_line =~ /^\s*(\(|\))\s*$/) {
                # looks like it, we'll bring it up to this line and skip it.
                $line =~ s/\n$//;
                print $ofh "$line$1\n";
            } else {
                # seek back to where we were, the next line wasn't a lonesome paren.
                seek($ifh, $pos, 0);
                
                # so just print it, there's nothing wrong with it!  hurrah!
                print $ofh $line;
            }
        }
    }
}

#!/usr/bin/perl

#########################################################################
#
# Copyright (c) 2006, 2007 Red Hat Incorporated.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#    Ben Konrath <bkonrath@redhat.com> - initial API and implementation
#
#########################################################################

# wspatch2patch.pl - converts Eclipse workspace patches to patches 
#                    compatible with the commandline patch utility.

	if (@ARGV != 1) {
		print STDERR "Converts an Eclipse \"workspace patch\" to a patch that can be used in rpm builds.\n"; 
		print STDERR "\tUsage: $0 path/to/eclipse/workspacepatch.patch\n"; 
		exit 1;
	}

	open( WSPATCH, "< $ARGV[0]" ) or die "Can't open $ARGV[0] : $!";

	$plugin='';
    	
	while( <WSPATCH> ) {
		if ($_ =~ m/^### Eclipse Workspace Patch 1.0/) {
			next;
		} elsif ($_ =~ m/^#P */) {
			$plugin = $_;
			$plugin =~ s/^#P //;	
			chomp($plugin);
			next;
		} elsif ($_ =~ m/^--- */) {
			$_ =~ s/^--- /--- plugins\/$plugin\//;
		} elsif ($_ =~ m/^\+\+\+ */) {
			$_ =~ s/^\+\+\+ /\+\+\+ plugins\/$plugin\//;
		}
		print STDOUT $_;
    	}

    	close WSPATCH;


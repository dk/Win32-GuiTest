#! /usr/bin/perl
# $Id: 99_pod_coverage.t,v 1.1 2007/10/23 12:22:49 pkaluski Exp $

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Test::Pod::Coverage required for testing POD coverage'
    if $@;
eval 'use Win32::GuiTest';
plan skip_all => 'Win32::GuiTest cannot be loaded'
    if $@;
my $skip = join '|', 
	( map { quotemeta } map {  @$_ } values %Win32::GuiTest::EXPORT_TAGS) ,
	qw(
		AllocateVirtualBufferImp
		DbgShow
		FindAndCheck
		FreeVirtualBufferImp
		GetHeaderColumnCount
		GetListViewHeader
		GetListViewItem
		GetListViewItemCount
		MatchTitleOrId
		MenuSelectItem
		ReadFromVirtualBufferImp
		SendKeysImp
		TVPathWalk
		WriteToVirtualBufferImp
	);
all_pod_coverage_ok( { 
	also_private => [ qr/^(MaybeAssoc|MaybeCommand)$/ ],
	trustme => [ qr/^($skip|[A-Z]{2,}(?:_[A-Z]{2,})+|[_a-z]+)$/ ],
} );

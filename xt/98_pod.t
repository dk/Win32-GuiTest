#! /usr/bin/perl
# $Id: 98_pod.t,v 1.1 2007/10/23 12:22:48 pkaluski Exp $

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok(all_pod_files('blib'));

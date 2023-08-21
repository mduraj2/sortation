#!/usr/bin/env perl

$version = '-1.1';

use File::Basename ();
$dir = File::Basename::dirname($0);

$job = `ps aux | grep Sortation | grep -v "perl $dir/Launch_sortation" | grep -v "grep pa" | awk {'print\$2'}`;
if ($job) {
system `kill $job`;
};
sleep 2;
system "open -a Terminal.app $dir/Sortation.command";

exit;
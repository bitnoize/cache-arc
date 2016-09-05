Cache-ARC
=========

An [Adaptive Replacement Cache (ARC)](https://en.wikipedia.org/wiki/Adaptive_replacement_cache) written in Perl.

Overview
--------

This is an implementation of "ARC", a self-tuning, low overhead replacement cache. Based on Alexander Gugel's [arc-js](https://github.com/alexanderGugel/arc-js).

Perfomance
----------

Classic Cache::LRU vs Cache::ARC compare using Celogeek's [benchmark](https://blog.celogeek.com/201401/426/perl-benchmark-cache-with-expires-and-max-size/):

```
$ ./test-cache-lru.pl 
Mapping
Starting
Write: 207530.954003361
Read : 1146092.21083581
Found: 2000
Mem  : 1077248

$ ./test-cache-arc.pl 
Mapping
Starting
Write: 76294.069827176
Read : 1160642.83625718
Found: 2000
Mem  : 806912

```


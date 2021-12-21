[![Actions Status](https://github.com/lizmat/highlighter/workflows/test/badge.svg)](https://github.com/lizmat/highlighter/actions)

NAME
====

highlighter - highlight something inside a string

SYNOPSIS
========

```raku
use highlighter;

say highlighter "foo bar", "bar", "<b>", "</b>", :type<words>; # foo <b>bar</b>

say highlighter "foo bar", "O", "*", :type<contains>, :ignorecase; # f*o**o* bar

say highlighter "foo bar", "fo", "*", :type<starts-with>;      # *fo*o bar

say highlighter "foo bar", / b.r /, "*";                       # foo *bar*
```

DESCRIPTION
===========

The highlighter distribution exports a single multi-dispatch subroutine `highlighter` that can be called to highlight a word, a string or the match of a regular expression inside a string.

All candidates of the `highlighter` subroutine take 4 positional parameters:

  * haystack

This is the string in which things should be highlighted.

  * needle

This is either a string, or a regular expression indicating what should be highlighted.

  * before

This is the string that should be put **before** the thing that should be highlighted.

  * after

Optional. This is the string that should be put **after** the thing that should be highlighted. Defaults to the `before` string>.

The following optional **named** arguments can also be specified:

  * type

Optional if the needle is a regular expression, otherwise obligatory.

It indicates the type of search that should be performed. Possible options are `words` (look for the needle at word boundaries only), `contains` (look for the needle at any position) and `starts-with` (only look for the needle at the start of the string).

  * ignorecase

If the second positional argument is a string, then this indicates whether any searches should be done in a case insensitive manner.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Elizabeth Mattijsen

Source can be located at: https://github.com/lizmat/highlighter . Comments and Pull Requests are welcome.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


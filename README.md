[![Actions Status](https://github.com/lizmat/highlighter/workflows/test/badge.svg)](https://github.com/lizmat/highlighter/actions)

NAME
====

highlighter - highlight something inside a string

SYNOPSIS
========

```raku
use highlighter;

say highlighter "foo bar", "bar", "<b>", "</b>", :type<words>; # foo <b>bar</b>

say columns "foo bar", "bar", :type<words>;       # (5)

say matches "foo bar", "O", :type<contains>, :ignorecase; # o o
```

DESCRIPTION
===========

The highlighter distribution exports three subroutines by default that are related to highlighting / indicating subsections of strings depending on the result of some type of search.

The `highlighter` subroutine can be called to highlight a word, a string or the match of a regular expression inside a string.

The `columns` subroutine returns the columns (1-based) at which highlighting should occur using the same search semantics as with `highlighter`.

The `matches` returns the actual matches inside the string as a `Slip`, using the same search semantics as with `highlighter`.

SELECTIVE IMPORTING
===================

```raku
use highlighter <columns>;  # only export sub columns
```

By default all three subroutines are exported. But you can limit this to the functions you actually need by specifying the name(s) in the `use` statement.

To prevent name collisions and/or import any subroutine with a more memorable name, one can use the "original-name:known-as" syntax. A semi-colon in a specified string indicates the name by which the subroutine is known in this distribution, followed by the name with which it will be known in the lexical context in which the `use` command is executed.

```raku
use highlighter <columns:the-columns>;  # export "columns" as "the-columns"

say the-columns "foo bar", "bar", :type<words>; # (5)
```

EXPORTED SUBROUTINES
====================

highlighter
-----------

The `highlighter` subroutine for a given string (the haystack), returns a string with highlighting codes for a word, a string or the match of a regular expression (the needle) with a given highlight string. Returns the haystack If the needle could not be found.

```raku
use highlighter;

say highlighter "foo bar", "bar", "<b>", "</b>", :type<words>; # foo <b>bar</b>

say highlighter "foo bar", "O", "*", :type<contains>, :ignorecase; # f*o**o* bar

say highlighter "foo bar", "fo", "*", :type<starts-with>;      # *fo*o bar

say highlighter "foo bar", "ar", "*", :type<ends-with>;        # foo b*ar*

say highlighter "foo bar", / b.r /, "*";                       # foo *bar*
```

The following positional parameters can be passed:

  * haystack

This is the string in which things should be highlighted.

  * needle

This is either a string, or a regular expression indicating what should be highlighted, or a list of strings / regular expressions.

If a list was specified, then the `highlighter` subroutine will be called for all elements in the list, and the first actually producing a highlighted string, will be returned.

  * before

This is the string that should be put **before** the thing that should be highlighted.

  * after

Optional. This is the string that should be put **after** the thing that should be highlighted. Defaults to the `before` string>.

The following optional named arguments can also be specified:

  * :type

Optional named argument. If the needle is a regular expression, it is ignored. Otherwise `"contains"` is assumed.

It indicates the type of search that should be performed. Possible options are `words` (look for the needle at word boundaries only), `contains` (look for the needle at any position), `starts-with` (only look for the needle at the start of the string) and `ends-with` (only look for the needle at the end of the string).

  * :ignorecase or :i

Optional named argument. If the second positional argument is a string, then this indicates whether any searches should be done in a case insensitive manner.

  * :ignoremark or :m

Optional named argument. If the second positional argument is a string, then this indicates whether any searches should be done on the base characters only.

  * :only

Optional named argument. Indicates that only the strings that were found should be returned (and not have anything inbetween, except for any `before` and `after` strings). Defaults to `False`.

  * :summary-if-larger-than

Optional named argument. Indicates the number of characters a string must exceed to have the non-highlighted parts shortened to try to fit the indicated number of characters. Defaults to `Any`, indicate no summarizing should take place.

columns
-------

The `columns` subroutine returns the columns (1-based) at which highlighting should occur, given a haystack, needle and optional named arguments.

```raku
use highlighter;

say columns "foo bar", "bar", :type<words>;       # (5)

say columns "foo bar", "O", :type<contains>, :ignorecase; # (2,3)

say columns "foo bar", "fo", :type<starts-with>;  # (1)

say columns "foo bar", "ar", :type<ends-with>;    # (6)

say columns "foo bar", / b.r /;                   # (5)
```

The following positional parameters can be passed:

  * haystack

This is the string in which should be searched to determine the column positions.

  * needle

This is either a string, or a regular expression indicating what should be searched for to determine the column positions, or a list of strings and regular exprssions.

If a list was specified, then the `columns` subroutine will be called for all elements in the list, and the first actually producing a result, will be returned.

The following named arguments can also be specified:

  * :type

Optional named argument. If the needle is a regular expression, it is ignored. Otherwise `"contains"` is assumed.

It indicates the type of search that should be performed. Possible options are `words` (look for the needle at word boundaries only), `contains` (look for the needle at any position), `starts-with` (only look for the needle at the start of the string) and `ends-with` (only look for the needle at the end of the string).

  * :ignorecase or :i

Optional named argument. If the second positional argument is a string, then this indicates whether any searches should be done in a case insensitive manner.

  * :ignoremark or :m

Optional named argument. If the second positional argument is a string, then this indicates whether any searches should be done on the base characters only.

matches
-------

The `matches` subroutine returns the actual matches inside the string as a `Slip` for the given haystack and needle and optional named arguments.

```raku
use highlighter;

say matches "foo bar", "bar", :type<words>;       # bar

say matches "foo bar", "O", :type<contains>, :ignorecase; # o o

say matches "foo bar", "fo", :type<starts-with>;  # fo

say matches "foo bar", "ar", :type<ends-with>;    # ar

say matches "foo bar", / b.r /;                   # bar
```

  * haystack

This is the string from which any matches should be returned.

  * needle

This is either a string, or a regular expression indicating what should be used to determine what a match is, or a list consisting of strings and regular expressions.

If a list was specified, then the `matches` subroutine will be called for all elements in the list, and the first actually producing a result, will be returned.

The following named arguments can also be specified:

  * :type

Optional named argument. If the needle is a regular expression, it is ignored. Otherwise `"contains"` is assumed.

It indicates the type of search that should be performed. Possible options are `words` (look for the needle at word boundaries only), `contains` (look for the needle at any position), `starts-with` (only look for the needle at the start of the string) and `ends-with` (only look for the needle at the end of the string).

  * :ignorecase or :i

Optional named argument. If the second positional argument is a string, then this indicates whether any searches should be done in a case insensitive manner.

  * :ignoremark or :m

Optional named argument. If the second positional argument is a string, then this indicates whether any searches should be done on the base characters only.

NOTES
=====

Callable as a needle
--------------------

If a simple `Callable` (rather than a `Regex`) is passed as a needle, then the haystack will **always** be returned, as there is no way to determine what will need to be highlighted. Any other arguments, apart from the `:summary-if-larger-than` named argument, will be ignored.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

COPYRIGHT AND LICENSE
=====================

Copyright 2021, 2022 Elizabeth Mattijsen

Source can be located at: https://github.com/lizmat/highlighter . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


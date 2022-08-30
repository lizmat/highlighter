use has-word:ver<0.0.3>:auth<zef:lizmat>;

my sub highlight-from-indices(
     str $haystack,
     str $needle,
     str $before,
     str $after,
  Bool() $found,
  Bool() $only,
         $summary-if-larger-than,
         \indices,
) {

    # something to highlight
    if indices.elems {
        my int $to   = chars($haystack);
        my int $size = chars($needle);
        my str @parts;

        # summarizing
        if !$only && $summary-if-larger-than && $to > $summary-if-larger-than {
            for indices.reverse -> int $pos {
                my int $between = $to - $pos - $size;
                @parts.unshift: $between < 31
                  ?? substr($haystack, $pos + $size, $between)
                  !! elems(@parts)
                    ?? substr($haystack, $pos + $size, 14)
                         ~ '...'
                         ~ substr($haystack, $pos + $size + $between - 14, 14)
                    !! substr($haystack, $pos + $size, 14) ~ '...';

                @parts.unshift: $after;
                @parts.unshift: $found
                  ?? substr($haystack, $pos, $size)
                  !! $needle;
                @parts.unshift: $before;
                $to = $pos;
            }

            if $to && !$only {
                @parts.unshift: $to < 15
                  ?? substr($haystack, 0, $to)
                  !! '...' ~ substr($haystack, $to - 11, 11)
            }
        }

        # NOT summarizing
        else {
            for indices.reverse -> int $pos {
                @parts.unshift:
                  $haystack.substr($pos + $size, $to - $pos - $size)
                  unless $only;
                @parts.unshift: $after;
                @parts.unshift: $found
                  ?? substr($haystack, $pos, $size)
                  !! $needle;
                @parts.unshift: $before;
                $to = $pos;
            }

            @parts.unshift: substr($haystack, 0, $to)
              if $to && !$only;
        }
        @parts.join
    }

    # nothing to highlight
    else {
        nothing($haystack, $summary-if-larger-than)
    }
}

# nothing to highlight
my sub nothing(str $haystack, $summary-if-larger-than) {
    $summary-if-larger-than && chars($haystack) > $summary-if-larger-than
      ?? substr($haystack, 0, $summary-if-larger-than - 3) ~ '...'
      !! $haystack
}

proto sub highlighter(|) is export {*}
multi sub highlighter(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D  $before,
  Str:D  $after = $before,
  Str:D :$type where $_ eq 'words',
        :$summary-if-larger-than,
        :i(:$ignorecase),
        :m(:$ignoremark),
        :$only,
--> Str:D) {
    highlight-from-indices(
      $haystack, $needle, $before, $after,
      $ignorecase || $ignoremark, $only, $summary-if-larger-than,
      find-all-words($haystack, $needle, :$ignorecase, :$ignoremark)
    )
}

multi sub highlighter(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D  $before,
  Str:D  $after = $before,
  Str:D :$type where $_ eq 'contains',
        :$summary-if-larger-than,
        :i(:$ignorecase),
        :m(:$ignoremark),
        :$only,
--> Str:D) {
    highlight-from-indices(
      $haystack, $needle, $before, $after,
      $ignorecase || $ignoremark, $only, $summary-if-larger-than,
      $haystack.indices($needle, :$ignorecase, :$ignoremark)
    )
}

multi sub highlighter(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D  $before,
   Str:D  $after = $before,
   Str:D :$type where $_ eq 'starts-with',
         :$only,
         :$summary-if-larger-than,
         :i(:$ignorecase),
         :m(:$ignoremark),
--> Str:D) {

    if $haystack.starts-with($needle, :$ignorecase, :$ignoremark) {
        if $only {
            $before ~ $needle ~ $after
        }
        else {
            my int $needle-size = $needle.chars;
            $before
              ~ $haystack.substr(0, $needle-size)
              ~ $after
              ~ ($summary-if-larger-than
                  && $haystack.chars > $summary-if-larger-than
                  ?? $haystack.substr(
                       $needle-size, $summary-if-larger-than - $needle-size - 3
                     ) ~ '...'
                  !! $haystack.substr($needle-size)
                )
        }
    }
    else {
        nothing($haystack, $summary-if-larger-than)
    }
}

multi sub highlighter(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D  $before,
   Str:D  $after = $before,
   Str:D :$type where $_ eq 'ends-with',
         :$only,
         :$summary-if-larger-than,
         :i(:$ignorecase),
         :m(:$ignoremark),
--> Str:D) {

    if $haystack.ends-with($needle, :$ignorecase, :$ignoremark) {
        if $only {
            $before ~ $needle ~ $after
        }
        else {
            my int $haystack-size = $haystack.chars;
            my int $needle-size   = $needle.chars;
            my int $pos = $haystack-size - $needle-size;
            ($summary-if-larger-than
              && $haystack-size > $summary-if-larger-than
              ?? '...' ~ $haystack.substr(
                   $pos - $summary-if-larger-than-3, $summary-if-larger-than-3
                 )
              !! $haystack.substr(0, $pos)
            ) ~ $before
              ~ $haystack.substr($pos)
              ~ $after
        }
    }
    else {
        nothing($haystack, $summary-if-larger-than)
    }
}

multi sub highlighter(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D  $before,
  Str:D  $after = $before,
        :$summary-if-larger-than,
        :i(:$ignorecase),
        :m(:$ignoremark),
        :$only,
--> Str:D) {
    highlight-from-indices(
      $haystack, $needle, $before, $after,
      $ignorecase || $ignoremark, $only, $summary-if-larger-than,
      $haystack.indices($needle, :$ignorecase, :$ignoremark)
    )
}

multi sub highlighter(
       Str:D  $haystack,
  Callable:D  $needle,
       Str:D  $before = "",
       Str:D  $after  = $before,
             :$summary-if-larger-than,
             :i(:$ignorecase),
             :m(:$ignoremark),
             :$only,
--> Str:D) {

    my int @fromtos;
    if Regex.ACCEPTS($needle) {
        my int $pos;
        my int $c;

        while $haystack.match($needle, :$c) {
            @fromtos.push: $/.to;
            @fromtos.push: $/.from;
            $c = $/.pos;
        }
    }

    # something to highlight
    if elems(@fromtos) {
        my int $to = $haystack.chars;
        my str @parts;
        if !$only && $summary-if-larger-than && $to > $summary-if-larger-than {
            for @fromtos.reverse -> int $from, int $pos {
                my int $between = $to - $pos;
                @parts.unshift: $between < 31
                  ?? substr($haystack, $pos, $between)
                  !! elems(@parts)
                    ?? substr($haystack, $pos, 14)
                         ~ '...'
                         ~ substr($haystack, $pos + $between - 14, 14)
                    !! substr($haystack, $pos, 14) ~ '...';

                @parts.unshift: $after;
                @parts.unshift: $haystack.substr($from, $pos - $from);
                @parts.unshift: $before;
                $to = $from;
            }
            if $to && !$only {
                @parts.unshift: $to < 15
                  ?? substr($haystack, 0, $to)
                  !! '...' ~ substr($haystack, $to - 11, 11)
            }
        }
        else {
            for @fromtos.reverse -> int $from, int $pos {
                @parts.unshift: $haystack.substr($pos, $to - $pos)
                  unless $only;
                @parts.unshift: $after;
                @parts.unshift: $haystack.substr($from, $pos - $from);
                @parts.unshift: $before;
                $to = $from;
            }
            @parts.unshift: $haystack.substr(0, $to)
              if $to && !$only;
        }
        @parts.join
    }

    # nothing to highlight
    else {
        nothing($haystack, $summary-if-larger-than)
    }
}

proto sub columns(|) is export {*}
multi sub columns(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D :$type where $_ eq 'words',
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    find-all-words($haystack, $needle, :$ignorecase, :$ignoremark).map: * + 1
}

multi sub columns(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D :$type where $_ eq 'contains',
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    $haystack.indices($needle, :$ignorecase, :$ignoremark).map: * + 1
}

multi sub columns(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D :$type where $_ eq 'starts-with',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> List:D) {
    $haystack.starts-with($needle, :$ignorecase, :$ignoremark)
      ?? BEGIN (1,)
      !! ()
}

multi sub columns(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D :$type where $_ eq 'ends-with',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> List:D) {
    $haystack.ends-with($needle, :$ignorecase, :$ignoremark)
      ?? ($haystack.chars - $needle.chars + 1,)
      !! ()
}

multi sub columns(
  Str:D  $haystack,
  Str:D  $needle,
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    $haystack.indices($needle, :$ignorecase, :$ignoremark).map: * + 1
}

multi sub columns(
       Str:D  $haystack,
  Callable:D  $needle,
             :i(:$ignorecase),
             :m(:$ignoremark),
) {

    if Regex.ACCEPTS($needle) {
        my int $c;
        my $columns := IterationBuffer.CREATE;

        while $haystack.match($needle, :$c) {
            $columns.push: $/.from + 1;
            $c = $/.pos;
        }

        $columns.List
    }
    else {
        BEGIN (0,)
    }
}

proto sub matches(|) is export {*}
multi sub matches(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D :$type where $_ eq 'words',
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    my int $chars = $needle.chars;
    find-all-words($haystack, $needle, :$ignorecase, :$ignoremark).map: {
        $haystack.substr($_,$chars)
    }
}

multi sub matches(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D :$type where $_ eq 'contains',
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    my int $chars = $needle.chars;
    $haystack.indices($needle, :$ignorecase, :$ignoremark).map: {
        $haystack.substr($_,$chars)
    }
}

multi sub matches(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D :$type where $_ eq 'starts-with',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> List:D) {
    $haystack.starts-with($needle, :$ignorecase, :$ignoremark)
      ?? ($haystack.substr(0,$needle.chars),)
      !! ()
}

multi sub matches(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D :$type where $_ eq 'ends-with',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> List:D) {
    $haystack.ends-with($needle, :$ignorecase, :$ignoremark)
      ?? ($haystack.substr(*-$needle.chars),)
      !! ()
}

multi sub matches(
  Str:D  $haystack,
  Str:D  $needle,
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    my int $chars = $needle.chars;
    $haystack.indices($needle, :$ignorecase, :$ignoremark).map: {
        $haystack.substr($_,$chars)
    }
}

multi sub matches(
       Str:D  $haystack,
  Callable:D  $needle,
             :i(:$ignorecase),
             :m(:$ignoremark),
) {

    if Regex.ACCEPTS($needle) {
        my int $c;
        my $columns := IterationBuffer.CREATE;

        while $haystack.match($needle, :$c) {
            $columns.push: $/.Str;
            $c = $/.pos;
        }

        $columns.List
    }
    else {
        BEGIN ()
    }
}

=begin pod

=head1 NAME

highlighter - highlight something inside a string

=head1 SYNOPSIS

=begin code :lang<raku>

use highlighter;

say highlighter "foo bar", "bar", "<b>", "</b>", :type<words>; # foo <b>bar</b>

say highlighter "foo bar", "O", "*", :type<contains>, :ignorecase; # f*o**o* bar

say highlighter "foo bar", "fo", "*", :type<starts-with>;      # *fo*o bar

say highlighter "foo bar", "ar", "*", :type<ends-with>;        # foo b*ar*

say highlighter "foo bar", / b.r /, "*";                       # foo *bar*


say columns "foo bar", "bar", :type<words>;       # (5)

say columns "foo bar", "O", :type<contains>, :ignorecase; # (2,3)

say columns "foo bar", "fo", :type<starts-with>;  # (1)

say columns "foo bar", "ar", :type<ends-with>;    # (6)

say columns "foo bar", / b.r /;                   # (5)


say matches "foo bar", "bar", :type<words>;       # bar

say matches "foo bar", "O", :type<contains>, :ignorecase; # o o

say matches "foo bar", "fo", :type<starts-with>;  # fo

say matches "foo bar", "ar", :type<ends-with>;    # ar

say matches "foo bar", / b.r /;                   # bar

=end code

=head1 DESCRIPTION

The highlighter distribution exports a multi-dispatch subroutine
C<highlighter> that can be called to highlight a word, a string or the
match of a regular expression inside a string.

It also exports a multi-dispatch subroutine C<columns> that returns the
columns (1-based) at which highlighting should occur.

And it also exports a multi-dispatch subroutine C<matches> that returns
the actual matches inside the string.

All candidates of the C<highlighter> subroutine take 4 positional
parameters.  All candidates of the C<columns> and C<matches> subroutine
take 2 positional parameters (with the same meaning of the first 2
positional parameters of C<highlighter>):

=item haystack

This is the string in which things should be highlighted.

=item needle

This is either a string, or a regular expression indicating what should be
highlighted.

=item before

This is the string that should be put B<before> the thing that should be
highlighted.  Only applicable with C<highlighter>.

=item after

Optional.  This is the string that should be put B<after> the thing that
should be highlighted.  Defaults to the C<before> string>.  Only
applicable with C<highlighter>.

The following optional B<named> arguments can also be specified:

=item :type

Optional named argument.  If the needle is a regular expression, it is
ignored.  Otherwise C<"contains"> is assumed.

It indicates the type of search that should be performed.  Possible options
are C<words> (look for the needle at word boundaries only), C<contains> (look
for the needle at any position), C<starts-with> (only look for the needle
at the start of the string) and C<ends-with> (only look for the needle at
the end of the string).

=item :ignorecase or :i

Optional named argument.  If the second positional argument is a string,
then this indicates whether any searches should be done in a case
insensitive manner.

=item :ignoremark or :m

Optional named argument.  If the second positional argument is a string,
then this indicates whether any searches should be done on the base
characters only.

=item :only

Optional named argument.  Indicates that only the strings that were found
should be returned (and not have anything inbetween, except for any
C<before> and C<after> strings).  Defaults to C<False>.  Only applicable
to C<highlighter>.

=item :summary-if-larger-than

Optional named argument.  Indicates the number of characters a string
must exceed to have the non-highlighted parts shortened to try to fit
the indicated number of characters.  Defaults to C<Any>, indicate no
summarizing should take place.  Only applicable to C<highlighter>.

=head1 NOTES

=head2 Callable as a needle

If a simple C<Callable> (rather than a C<Regex>) is passed as a needle,
then the haystack will B<always> be returned, as there is no way to
determine what will need to be highlighted.  Any other arguments, apart
from the C<:summary-if-larger-than> named argument, will be ignored.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

=head1 COPYRIGHT AND LICENSE

Copyright 2021, 2022 Elizabeth Mattijsen

Source can be located at: https://github.com/lizmat/highlighter .
Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a
L<small sponsorship|https://github.com/sponsors/lizmat/>  would mean a great
deal to me!

This library is free software; you can redistribute it and/or modify it
under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4

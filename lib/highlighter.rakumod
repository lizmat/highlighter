use has-word:ver<0.0.2>:auth<zef:lizmat>;

my $cursor-init := Match.^lookup("!cursor_init");

my sub highlight-from-indices(
  str $haystack,
  str $needle,
  str $before,
  str $after,
      $ignorecase,
      \indices,
) {
    my int $chars = $needle.chars;
    my int $to    = $haystack.chars;
    my str @parts;
    for indices.reverse -> int $pos {
        @parts.unshift: $haystack.substr($pos + $chars, $to - $pos - $chars);
        @parts.unshift: $after;
        @parts.unshift: $ignorecase
          ?? $haystack.substr($pos, $chars)
          !! $needle;
        @parts.unshift: $before;
        $to = $pos;
    }

    if $to == $haystack.chars {   # no highlighting whatsoever
        $haystack
    }
    else {
        @parts.unshift($haystack.substr(0, $to)) if $to;
        @parts.join
    }
}

proto sub highlighter(|) is export {*}
multi sub highlighter(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D  $before,
  Str:D  $after = $before,
  Str:D :$type where $_ eq 'words',
        :$ignorecase,
--> Str:D) {
    highlight-from-indices(
      $haystack, $needle, $before, $after, $ignorecase,
      find-all-words($haystack, $needle, :$ignorecase)
    )
}

multi sub highlighter(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D  $before,
  Str:D  $after = $before,
  Str:D :$type where $_ eq 'contains',
        :$ignorecase,
--> Str:D) {
    highlight-from-indices(
      $haystack, $needle, $before, $after, $ignorecase,
      $haystack.indices($needle, :$ignorecase)
    )
}

multi sub highlighter(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D  $before,
  Str:D  $after = $before,
  Str:D :$type where $_ eq 'starts-with',
        :$ignorecase,
--> Str:D) {
    my int $chars = $needle.chars;
    $haystack.starts-with($needle, :$ignorecase)
      ?? $before
           ~ $haystack.substr(0,$chars)
           ~ $after
           ~ $haystack.substr($chars)
      !! $haystack
}

multi sub highlighter(
    Str:D  $haystack,
  Regex:D  $regex,
    Str:D  $before,
    Str:D  $after = $before,
--> Str:D) {
    my     $cursor;
    my int $pos;
    my int $c;
    my int @fromtos;

    while ($pos = (
      $cursor := $regex($cursor-init(Match, $haystack, :$c))
    ).pos) > -1 {
        @fromtos.push: $c = $pos;
        @fromtos.push: $cursor.from;
    }

    my int $to = $haystack.chars;
    my str @parts;
    for @fromtos.reverse -> int $from, int $pos {
        @parts.unshift: $haystack.substr($pos, $to - $pos);
        @parts.unshift: $after;
        @parts.unshift: $haystack.substr($from, $pos - $from);
        @parts.unshift: $before;
        $to = $from;
    }

    if $to == $haystack.chars {   # no highlighting whatsoever
        $haystack
    }
    else {
        @parts.unshift($haystack.substr(0, $to)) if $to;
        @parts.join
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

say highlighter "foo bar", / b.r /, "*";                       # foo *bar*

=end code

=head1 DESCRIPTION

The highlighter distribution exports a single multi-dispatch subroutine
C<highlighter> that can be called to highlight a word, a string or the
match of a regular expression inside a string.

All candidates of the C<highlighter> subroutine take 4 positional parameters:

=item haystack

This is the string in which things should be highlighted.

=item needle

This is either a string, or a regular expression indicating what should be
highlighted.

=item before

This is the string that should be put B<before> the thing that should be
highlighted.

=item after

Optional.  This is the string that should be put B<after> the thing that
should be highlighted.  Defaults to the C<before> string>.

The following optional B<named> arguments can also be specified:

=item type

Optional if the needle is a regular expression, otherwise obligatory.

It indicates the type of search that should be performed.  Possible options
are C<words> (look for the needle at word boundaries only), C<contains> (look
for the needle at any position) and C<starts-with> (only look for the needle
at the start of the string).

=item ignorecase

If the second positional argument is a string, then this indicates whether
any searches should be done in a case insensitive manner.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

Source can be located at: https://github.com/lizmat/highlighter .
Comments and Pull Requests are welcome.

This library is free software; you can redistribute it and/or modify it
under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4

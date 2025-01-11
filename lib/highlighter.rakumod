#-------------------------------------------------------------------------------
# Compile time setup

use has-word:ver<0.0.6+>:auth<zef:lizmat>;   # has-word
use String::Utils:ver<0.0.32+>:auth<zef:lizmat> <
  has-marks is-lowercase
>;

my constant @ok-types = <contains words starts-with ends-with equal>;
my constant %ok-types = @ok-types.map: * => 1;

my role Type {
    has $.type;

    method TWEAK() is hidden-from-backtrace {
        die qq:to/ERROR/ unless %ok-types{$!type};
Type must be one of:
  @ok-types.join("\n  ")
not: '$!type'
ERROR
    }
}

#------------------------------------------------------------------------------0
# Helper subroutines

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
    $summary-if-larger-than
      && chars($haystack) > $summary-if-larger-than
      && !$*SKIP-NOTHING
      ?? substr($haystack, 0, $summary-if-larger-than - 3) ~ '...'
      !! $haystack
}

#-------------------------------------------------------------------------------
# "highlighter" logic

proto sub highlighter(|) is export {*}

# Pre-processing "smartcase"
multi sub highlighter(
  Str:D $haystack, Str:D $needle, Str:D $before, Str:D $after = $before,
  :$ignorecase, :$smartcase!, *%_
--> Str:D) {
    %_<ignorecase> := $ignorecase || ($smartcase && is-lowercase($needle));
    highlighter($haystack, $needle, $before, $after, |%_)
}

# Pre-processing "smartmark"
multi sub highlighter(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D  $before,
  Str:D  $after = $before,
        :$ignoremark,
        :$smartmark!,
        *%_
--> Str:D) {
    %_<ignoremark> = $ignoremark || ($smartmark && !has-marks($needle));
    highlighter($haystack, $needle, $before, $after, |%_)
}

# Handle "words" highlighting
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

# Handle default and "contains" highlighting
multi sub highlighter(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D  $before,
  Str:D  $after = $before,
  Str:D :$type where !.defined || $_ eq 'contains',
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

# Handle "starts-with" highlighting
multi sub highlighter(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D  $before,
   Str:D  $after = $before,
   Str:D :$type where $_ eq 'starts-with',
         :$summary-if-larger-than,
         :i(:$ignorecase),
         :m(:$ignoremark),
         :$only,
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

# Handle "ends-with" highlighting
multi sub highlighter(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D  $before,
   Str:D  $after = $before,
   Str:D :$type where $_ eq 'ends-with',
         :$summary-if-larger-than,
         :i(:$ignorecase),
         :m(:$ignoremark),
         :$only,
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
                   $pos - $summary-if-larger-than -3, $summary-if-larger-than -3
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

# Handle "equal" highlighting
multi sub highlighter(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D  $before,
   Str:D  $after = $before,
   Str:D :$type where $_ eq 'equal',
         :$summary-if-larger-than,
         :i(:$ignorecase),
         :m(:$ignoremark),
         :$only,
--> Str:D) {

    my int $haystack-size = $haystack.chars;
    my int $needle-size   = $needle.chars;

    $haystack-size == $needle-size
      && $haystack.index($needle, :$ignorecase, :$ignoremark).defined
      ?? $before
           ~ ($summary-if-larger-than && $haystack-size>$summary-if-larger-than
               ?? $haystack.substr(0, $summary-if-larger-than - 3) ~ '...'
               !! $haystack
             )
           ~ $after
      !! nothing($haystack, $summary-if-larger-than)
}

# Pre-process mixed in typing
multi sub highlighter(Str:D $haystack, Str:D $needle, |c --> Str:D) {
    highlighter
      $haystack,
      $needle,
      :type(Type.ACCEPTS($needle) ?? $needle.type !! 'contains'),
      |c
}

# Handle Callable needle (aka Regex)
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

# Pre-process multiple needles
multi sub highlighter(
  Str:D  $haystack,
         @needles,
        :$summary-if-larger-than is copy,
        |c
) {

    # Make sure no summarizing if no highlighting was done
    my $*SKIP-NOTHING = True;

    my $highlighted = $haystack;
    for @needles {
        if Pair.ACCEPTS($_) {
            $highlighted := highlighter(
              $highlighted, .value, :type(.key), :$summary-if-larger-than, |c
            );
        }
        elsif Regex.ACCEPTS($_) || !Callable.ACCEPTS($_) {
            $highlighted := highlighter(
              $highlighted, $_, :$summary-if-larger-than, |c
            );
        }
        $summary-if-larger-than = Any if $highlighted ne $haystack;
    }

    if $highlighted eq $haystack {
        $*SKIP-NOTHING = False;
        nothing($highlighted, $summary-if-larger-than)
    }
    else {
        $highlighted
    }
}

#-------------------------------------------------------------------------------
# "columns" logic

proto sub columns(|) is export {*}

# Pre-processing "smartcase"
multi sub columns(
  Str:D  $haystack,
  Str:D  $needle,
        :$ignorecase,
        :$smartcase!,
        *%_
) {
    %_<ignorecase> := $ignorecase || ($smartcase && is-lowercase($needle));
    columns($haystack, $needle, |%_)
}

# Pre-processing "smartmark"
multi sub columns(
  Str:D  $haystack,
  Str:D  $needle,
        :$ignoremark,
        :$smartmark!,
        *%_
) {
    %_<ignoremark> = $ignoremark || ($smartmark && !has-marks($needle));
    columns($haystack, $needle, |%_)
}

# Handle "words" columns
multi sub columns(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D :$type where $_ eq 'words',
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    find-all-words($haystack, $needle, :$ignorecase, :$ignoremark).map: * + 1
}

# Handle "contains" columns
multi sub columns(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D :$type where $_ eq 'contains',
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    $haystack.indices($needle, :$ignorecase, :$ignoremark).map: * + 1
}

# Handle "starts-with" columns
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

# Handle "ends-with" columns
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

# Handle "equal" columns
multi sub columns(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D :$type where $_ eq 'equal',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> List:D) {
    $haystack.chars == $needle.chars
      && $haystack.index($needle, :$ignorecase, :$ignoremark).defined
      ?? BEGIN (1,)
      !! ()
}

# Pre-process mixed-in typing columns
multi sub columns(Str:D  $haystack, Str:D  $needle, *%_ --> Seq:D) {
    columns
      $haystack,
      $needle,
      :type(Type.ACCEPTS($needle) ?? $needle.type !! 'contains'),
      |%_
}

# Handle Callable columns (aka Regex)
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
        ()
    }
}

# Handle multiple columns
multi sub columns(Str:D $haystack, @needles, |c) {
    for @needles {
        if Regex.ACCEPTS($_) || !Callable.ACCEPTS($_) {
            columns(
              $haystack, $_, |c
            ).iterator.push-all(my $ib := IterationBuffer.new);
            return $ib.List if $ib.elems;
        }
    }
    ()
}

#-------------------------------------------------------------------------------
# "matches" logic

proto sub matches(|) is export {*}

# Pre-processing "smartcase"
multi sub matches(
  Str:D  $haystack,
  Str:D  $needle,
        :$ignorecase,
        :$smartcase!,
        *%_
--> Slip:D) {
    %_<ignorecase> := $ignorecase || ($smartcase && is-lowercase($needle));
    matches($haystack, $needle, |%_)
}

# Pre-processing "smartmark"
multi sub matches(
  Str:D  $haystack,
  Str:D  $needle,
        :$ignoremark,
        :$smartmark!,
        *%_
--> Slip:D) {
    %_<ignoremark> = $ignoremark || ($smartmark && !has-marks($needle));
    matches($haystack, $needle, |%_)
}

# Handle "words" matches
multi sub matches(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D :$type where $_ eq 'words',
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Slip:D) {
    my int $chars = $needle.chars;
    find-all-words($haystack, $needle, :$ignorecase, :$ignoremark).map({
        $haystack.substr($_,$chars)
    }).Slip // Empty
}

# Handle "contains" matches
multi sub matches(
  Str:D  $haystack,
  Str:D  $needle,
  Str:D :$type where $_ eq 'contains',
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Slip:D) {
    my int $chars = $needle.chars;
    $haystack.indices($needle, :$ignorecase, :$ignoremark).map({
        $haystack.substr($_,$chars)
    }).Slip // Empty
}

# Handle "starts-with" matches
multi sub matches(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D :$type where $_ eq 'starts-with',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> Slip:D) {
    $haystack.starts-with($needle, :$ignorecase, :$ignoremark)
      ?? slip($haystack.substr(0,$needle.chars))
      !! Empty
}

# Handle "ends-with" matches
multi sub matches(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D :$type where $_ eq 'ends-with',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> Slip:D) {
    $haystack.ends-with($needle, :$ignorecase, :$ignoremark)
      ?? slip($haystack.substr(*-$needle.chars))
      !! Empty
}

# Handle "equal" matches
multi sub matches(
   Str:D  $haystack,
   Str:D  $needle,
   Str:D :$type where $_ eq 'equal',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> Slip:D) {
    $haystack.chars == $needle.chars
      && $haystack.index($needle, :$ignorecase, :$ignoremark).defined
      ?? slip($haystack)
      !! Empty
}

# Pre-process mixed-in types
multi sub matches(
  Str:D  $haystack,
  Str:D  $needle,
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Slip:D) {
    matches
      $haystack,
      $needle,
      :type(Type.ACCEPTS($needle) ?? $needle.type !! 'contains')
      :$ignorecase
      :$ignoremark
}

# Handle Callable matches (aka Regex)
multi sub matches(
       Str:D  $haystack,
  Callable:D  $needle,
             :i(:$ignorecase),
             :m(:$ignoremark),
--> Slip:D) {

    if Regex.ACCEPTS($needle) {
        my int $c;
        my $columns := IterationBuffer.CREATE;

        while $haystack.match($needle, :$c) {
            $columns.push: $/.Str;
            $c = $/.pos;
        }

        $columns.Slip // Empty
    }
    else {
        Empty
    }
}

# Pre-process multiple matches
multi sub matches(Str:D $haystack, @needles, |c) {
    for @needles {
        if Regex.ACCEPTS($_) || !Callable.ACCEPTS($_) {
            my $slip := matches($haystack, $_, |c);
            return $slip unless $slip =:= Empty;
        }
    }
    Empty
}

#-------------------------------------------------------------------------------
# Subroutine exporting logic

my sub EXPORT(*@names) {
    Map.new: @names
      ?? @names.map: {
             if $_ eq 'Type' {
                 Type => Type
             }
             elsif UNIT::{"&$_"}:exists {
                 UNIT::{"&$_"}:p
             }
             else {
                 my ($in,$out) = .split(':', 2);
                 if $out {
                     if $in eq 'Type' {
                         Pair.new: $out, Type
                     }
                     elsif UNIT::{"&$in"} -> &code {
                         Pair.new: "&$out", &code
                     }
                 }
             }
         }
      !! UNIT::.grep: {
             .key eq 'Type'
               || (.key.starts-with('&') && .key ne '&EXPORT')
         }
}

# vim: expandtab shiftwidth=4

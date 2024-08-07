use has-word:ver<0.0.4>:auth<zef:lizmat>;

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

multi sub highlighter(Str:D $haystack, Str:D $needle, |c --> Str:D) {
    highlighter
      $haystack,
      $needle,
      :type(Type.ACCEPTS($needle) ?? $needle.type !! 'contains'),
      |c
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

multi sub highlighter(Str:D $haystack, @needles, :$summary-if-larger-than, |c) {
    my $highlighted = $haystack;
    for @needles {
        if Regex.ACCEPTS($_) || !Callable.ACCEPTS($_) {
            my $highlighted := highlighter($haystack, $_, |c);
            if $highlighted ne $haystack {
                return $summary-if-larger-than
                  ?? highlighter($haystack, $_, :$summary-if-larger-than, |c)
                  !! $highlighted
            }
        }
    }
    $haystack
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
   Str:D :$type where $_ eq 'equal',
         :i(:$ignorecase),
         :m(:$ignoremark),
--> List:D) {
    $haystack.chars == $needle.chars
      && $haystack.index($needle, :$ignorecase, :$ignoremark).defined
      ?? BEGIN (1,)
      !! ()
}

multi sub columns(
  Str:D  $haystack,
  Str:D  $needle,
        :i(:$ignorecase),
        :m(:$ignoremark),
--> Seq:D) {
    columns
      $haystack,
      $needle,
      :type(Type.ACCEPTS($needle) ?? $needle.type !! 'contains'),
      :$ignorecase,
      :$ignoremark
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
        ()
    }
}

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

proto sub matches(|) is export {*}
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

multi sub matches(Str:D $haystack, @needles, |c) {
    for @needles {
        if Regex.ACCEPTS($_) || !Callable.ACCEPTS($_) {
            my $slip := matches($haystack, $_, |c);
            return $slip unless $slip =:= Empty;
        }
    }
    Empty
}

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

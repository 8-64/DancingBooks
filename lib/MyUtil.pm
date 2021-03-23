package MyUtil v1.1.0 {
    use v5.23;
    use feature ':all';
    use warnings; no warnings 'experimental';
    use utf8;

    state $flag_offset  = 0x1F1E6;
    state $ascii_offset = 0x41;
    sub CountryToEmoji ($country) {
        my $first  = substr($country, 0, 1);
        my $second = substr($country, 1, 1);

        $first  = ord($first) - $ascii_offset + $flag_offset;
        $second = ord($second) - $ascii_offset + $flag_offset;

        sprintf('&#x%0x;&#x%0x;', $first, $second); # HTML output
    }

    sub EditInPlace ($what, $with, @files) {
        @files = grep { -r -f } @files;
        local $^I   = '.bak'; # Classical backup extension. NOTE: It will pile up "*.bak.bak.bak.bak"'s with every run without cleanup 
        local @ARGV = @files;
        while (<>) {
            s/$what/$with/gn;
            print;
        }
    }

    1;
}

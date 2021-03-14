package MyUtil v1.0.0 {
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

    1;
}

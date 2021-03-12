package MyModel v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings; no warnings 'experimental';
    use utf8;

    use Date::Manip 'ParseDate';

    sub Curry ($arg, $sub) { sub (@args) { $sub->($arg, @args) } }

    sub upTo ($size, $arg) {
        die(bless \"Parameter size too large (over $size)" => 'MyModel::Error') if (length $arg > $size);
        $arg;
    }
    sub toCountry ($arg) { $arg = uc $arg; $arg =~ tr/A-Z//cd; substr($arg, 0, 2) }
    sub toDate ($arg) { ParseDate($arg) }
    sub toInt ($arg) { int $arg }
    sub toISBN ($arg) { $arg =~ tr/0-9-//cd; $arg }
    sub Sanitize ($text) { $text =~ s/[^[:print:][:space:]]//gnm; $text }

    my %attributes = (
        book => {             #      POLICY       |    PROCESSING
            author         => [ 'passthrough' ],
            id             => [ 'skip if missing', [ \&toInt ] ],
            isbn           => [ 'default',         [ Curry(18, \&upTo), \&toISBN ] ],
            title          => [ 'mandatory',       [ Curry(100, \&upTo), \&Sanitize ] ],
            date_published => [ 'default',         [ Curry(50, \&upTo), \&Sanitize, \&toDate ] ],
        },
        author => {
            book           => [ 'passthrough' ],
            id             => [ 'skip if missing', [ \&toInt ] ],
            country        => [ 'default',         [ Curry(3, \&upTo), \&Sanitize, \&toCountry ] ],
            name           => [ 'mandatory',       [ Curry(100, \&upTo), \&Sanitize ] ],
            surname        => [ 'default',         [ Curry(200, \&upTo), \&Sanitize ] ],
        },
    );

    sub As ($what, $data, @modifiers) {
        my %modifiers = map { $_, 1 } @modifiers;
        my $sanitized = {};
        while (my ($attribute, $processing) = each $attributes{$what}->%*) {
            given ($processing->[0]) {
                when ('passthrough') {
                    next unless exists $data->{$attribute};
                    $sanitized->{$attribute} = $data->{$attribute};
                    next;
                }
                when ('skip if missing') {
                    next unless exists $data->{$attribute};
                }
                when ('mandatory') {
                    die(bless \"Parameter [$attribute] was not supplied!" => 'MyModel::Error') unless exists $data->{$attribute};
                }
                when ('default') {
                    unless (exists $data->{$attribute}) {
                        $sanitized->{$attribute} = '';
                    }
                }
                default { warn("Unknown option: $_") }
            }

            my $value = $data->{$attribute};
            foreach my $processor ($processing->[1]->@*) {
                $value = $processor->($value);
            }
            $sanitized->{$attribute} = $value;
        }

        return 1 if $modifiers{'-check'};
        defined wantarray? $sanitized : ($data = $sanitized);
    }
    1;
}

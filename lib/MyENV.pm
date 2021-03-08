package MyENV v1.0.0 {
    sub import { shift; while (my $k = shift) { $ENV{$k} = shift } }
    1;
}

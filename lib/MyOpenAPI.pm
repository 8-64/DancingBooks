package MyOpenAPI v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use Dancer2; no warnings 'experimental';

    use DescribeMyOpenAPI;

    my $handler = sub ($dancer) {
        my @params = params('query');
        my $type = 'json';
        my $content_type = 'application/json';
        if (defined($params[0]) and lc $params[0] eq 'yaml') {
            $type = 'yaml';
            $content_type = 'text/yaml';
        }

        set content_type => $content_type;
        DescribeMyOpenAPI::Show($type);
    };

    get '/?'        => $handler;
    get 'openAPI/?' => $handler;

    1;
}

package MyCMD v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use Dancer2; no warnings 'experimental';
    use Dancer2::Plugin::DBIC;

    use Data::Dumper 'Dumper';

    prefix '/cmd' if (${^RM} eq 'Dancer');
    set content_type => 'text/plain';

    get '/exit/?'    => sub { exit 0 };
    get '/showsql/?' => sub { schema()->deployment_statements };
    get '/dumpenv/?' => sub ($dancer) { Dumper $dancer };

    1;
}

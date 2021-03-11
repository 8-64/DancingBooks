#!/usr/bin/perl

use v5.23;
use feature ':all';
use warnings; no warnings 'experimental';
use utf8;

use FindBin qw[$RealBin];
my $root_dir;
BEGIN {
    $root_dir = ($RealBin =~ s:[^\w](bin|t|lib.+)\z::r);
}
use lib "$root_dir/lib";

use Encode qw[encode_utf8];
use JSON::MaybeXS;
use HTTP::Request::Common;
use Plack::Test;
use Test::More;

my $app = do "$root_dir/app.pl";
my $app_test = Plack::Test->create($app);

my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

# 1-2: Request nonexistant address
my $res = $app_test->request(GET "/BlaBlaBla");
is($res->code, 404, 'Returned 404 when address is wrong');
like($res->content, qr/Not Found/, 'There is "Not Found" in the page body');

# 3-10:
# GET and POST should return JSONs for "api/books" and "api/authors"
foreach my $method (\&GET, \&POST) {
    foreach my $catalogue_endpoint ('api/books', 'api/authors') {
        $res = $app_test->request($method->($catalogue_endpoint));
        is($res->code, 200, "Returned 200 code, at $catalogue_endpoint");
        my $data = decode_json($res->content);
        my $n_items = scalar @$data;
        ok($n_items > 5, "There are multiple ($n_items) items in the responce");
    }
}

done_testing();

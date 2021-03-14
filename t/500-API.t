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
use HTTP::Request::Common qw[GET PUT POST PATCH DELETE];
use Plack::Test;
use Test::More;

my $app = do "$root_dir/app.pl";
my $app_test = Plack::Test->create($app);

my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

# 1-2: Request nonexistant address
my $res = $app_test->request(GET "/BlaBlaBla");
is($res->code, 404, 'Returned 404 when address is wrong');
like($res->content, qr/Not Found/, 'There is "Not Found" in the page body');

# 3-14:
# GET and POST should return JSONs for "api/books" and "api/authors"
my %returned_data;
foreach my $method (\&GET, \&POST) {
    foreach my $catalogue_endpoint ('api/books', 'api/authors') {
        $res = $app_test->request($method->($catalogue_endpoint));
        is($res->code, 200, "Returned 200 code, at $catalogue_endpoint");

        like($res->header('Content-Type'), qr/json/, 'JSON was returned');

        my $data = decode_json($res->content);
        $returned_data{$catalogue_endpoint} = $data;
        my $n_items = $#$data + 1;
        ok($n_items > 5, "There are multiple ($n_items) items in the responce");
    }
}

# 15-22:
# Check that individual item is returned at "api/books/:id" and "api/authors/:id", it is JSON, and it has some key-value pairs
foreach my $catalogue_endpoint ('api/books', 'api/authors') {
    my $first_item = $returned_data{$catalogue_endpoint}->[0];
    ok((exists $first_item->{title} or exists $first_item->{name}), 'Necessary part is present in the responce');

    my $item_path = $catalogue_endpoint.'/'.$first_item->{id};
    $res = $app_test->request(GET $item_path);
    is($res->code, 200, "Returned 200 code, at [$item_path]");

    like($res->header('Content-Type'), qr/json/, 'JSON was returned');

    my $data = decode_json($res->content);
    my $n_items = scalar keys %$data;
    ok($n_items > 2, "There are multiple ($n_items) items in the responce");
}

# 23-42
# SCENARIO:
# No such book/author is present
# Add an author/book
# Is it there now?
# Try to add the same item again -> it should fail
# Delete it
# There is no such book/author again
foreach my $type ('books', 'authors') {
    my $randid = 100 + int rand 1_000_000;
    my $item_path = "api/$type/$randid";
    # just to be sure
    $app_test->request(DELETE $item_path);
    $res = $app_test->request(GET $item_path);
    is($res->code, 404, "Item [$item_path] not found, as expected");

    my $json_to_send = GiveMe($type, $randid);
    $res = $app_test->request(PUT $item_path, Header => $header, Content => $json_to_send);
    is($res->code, 201, "Item [$item_path] was created");

    like($res->header('Content-Type'), qr/json/, 'JSON was returned');

    like($res->content, qr/OK created/, 'There is "OK created" in the responce');

    $res = $app_test->request(GET $item_path);
    is($res->code, 200, "Item [$item_path] was found, after creation");

    $res = $app_test->request(PUT $item_path, Header => $header, Content => $json_to_send);
    is($res->code, 409, "Item [$item_path] can't rewrite existing one");

    like($res->content, qr/There\s+is\s+already/, 'There is a warning in the body');

    $res = $app_test->request(DELETE $item_path);
    is($res->code, 200, "Item [$item_path] was deleted");

    like($res->content, qr/OK deleted/, 'Deletion confirmed');

    $res = $app_test->request(GET $item_path);
    is($res->code, 404, "Item [$item_path] not found again");
}

# 43-48
# SCENARIO:
# modify individual item
# It is modified successfully
foreach my $catalogue_endpoint ('api/books', 'api/authors') {
    my $first_item = $returned_data{$catalogue_endpoint}->[0];
    my ($original, $reversed, $field);
    if (exists $first_item->{title}) {
        $field = 'title';
    } elsif (exists $first_item->{name}) {
        $field = 'name';
    }
    $original = $first_item->{$field};
    $reversed = reverse $original;
    $first_item->{$field} = $reversed;

    my $item_path = $catalogue_endpoint.'/'.$first_item->{id};
    $res = $app_test->request(PATCH $item_path, Header => $header, Content => encode_utf8(encode_json($first_item)));
    is($res->code, 200, "Item [$item_path] was patched");

    like($res->content, qr/OK patched/, 'Patching confirmed');

    $res = $app_test->request(GET $item_path);
    my $data = decode_json($res->content);
    ok($data->{$field} eq $reversed, "Item [$item_path] has [$field] reversed and stored");
}

END {
    # Perform cleanup at the end
    
}

done_testing();

sub GiveMe ($what, $randid) {
    given ($what) {
        when (/authors?/i) {
        <<~"HDOC";
        {
            "country":"FR",
            "book":[
                {
                    "isbn":"",
                    "date_published":"January 2020",
                    "id":@{[ 100 + int rand 1_000_000 ]},
                    "title":"Think Raku How to Think Like a Computer Scientist"
                }
            ],
            "surname":"Rosenfeld",
            "name":"Laurent",
            "id":${randid}
        }
        HDOC
        }

        when (/books?/i) {
            <<~"HDOC";
            {
                "isbn":"978-0-7869-3946-6",
                "date_published":"October 2006",
                "id":${randid},
                "author":[
                    {
                        "id":@{[ 100_000 + int rand 100_000 ]},
                        "country":"US",
                        "surname":"R. Cordell",
                        "name":"Bruce"
                    },
                    {
                        "country":"US",
                        "id":@{[ 200_000 + int rand 100_000 ]},
                        "name":"James",
                        "surname":"Wyatt"
                    }
                ],
                "title":"Expedition to Castle Ravenloft"
            }
            HDOC
        }
    }
}

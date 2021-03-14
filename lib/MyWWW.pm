package MyWWW v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use Dancer2; no warnings 'experimental';
    use Dancer2::Plugin::DBIC;

    use MyUtil;
    use MyStorageModel;

    get 'index.html' => sub ($dancer) {
        template "templates/index.tx", { title => 'Book catalogue title page' };
    };

    get '/books/?' => sub ($dancer) {
        my $schema = schema;

        my $result = [];
        foreach my $book ( $schema->resultset('Book')->search( {} )->all ) {
            push (@$result, { $book->get_columns });
        }
        # Sort books alphabetically
        @$result = sort { $a->{title} cmp $b->{title} } @$result;
        template "templates/books.tx", { title => 'Book listing', books => $result };
    };

    get '/books/:id' => sub ($dancer) {
        my $id = int route_parameters->get('id');

        my $schema = schema;
        my $result = {};

        my $book = $schema->resultset('Book')->search( {id => $id} )->first;
        send_error("Book with id [$id] not found!", 404) unless (defined $book);

        $result = MyStorageModel::GetBookInfo($book, $schema);

        template "templates/book.tx", { title => 'Book information', book => $result };
    };

    get '/authors/?' => sub ($dancer) {
        my $schema = schema;

        my $result = [];
        foreach my $author ( $schema->resultset('Author')->search( {} )->all ) {
            push (@$result, { $author->get_columns });
        }

        # Convert country codes to HTML emojis
        $_->{country} = MyUtil::CountryToEmoji($_->{country}) foreach @$result;

        # Sort authors by surname alphabetically
        @$result = sort { $a->{surname} cmp $b->{surname} } @$result;
        template "templates/authors.tx", { title => 'Authors listing', authors => $result };
    };

    get '/authors/:id' => sub ($dancer) {
        my $id = int route_parameters->get('id');

        my $schema = schema;
        my $result = {};

        my $author = $schema->resultset('Author')->search( {id => $id} )->first;
        send_error("Author with id [$id] not found!", 404) unless (defined $author);

        $result = MyStorageModel::GetAuthorInfo($author, $schema);
        $result->{country} = MyUtil::CountryToEmoji($result->{country});

        template "templates/author.tx", { title => 'Author information', author => $result };
    };

    1;
}

package MyWWW v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use Dancer2; no warnings 'experimental';
    use Dancer2::Plugin::DBIC;

    use MyUtil;

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

        %$result = $book->get_columns;
        my @authors_rs = $book->search_related('book_authors');
        my @author_ids;
        push (@author_ids, $_->author_id) foreach @authors_rs;
        my @authors = $schema->resultset('Author')->search( {id => [ @author_ids ]} )->all;
        push ($result->{author}->@*, { $_->get_columns }) foreach @authors;

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

        %$result = $author->get_columns;
        $result->{country} = MyUtil::CountryToEmoji($result->{country});
        my @books_rs = $author->search_related('book_authors');
        my @book_ids;
        push (@book_ids, $_->book_id) foreach @books_rs;
        my @books = $schema->resultset('Book')->search( {id => [ @book_ids ]} )->all;
        push ($result->{book}->@*, { $_->get_columns }) foreach @books;

        template "templates/author.tx", { title => 'Author information', author => $result };
    };

    1;
}

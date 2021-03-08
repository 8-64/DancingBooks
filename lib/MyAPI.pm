package MyAPI v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use Dancer2; no warnings 'experimental';
    use Dancer2::Plugin::DBIC;

    use Data::Dumper 'Dumper';

    prefix '/api' => sub {
        set content_type => 'application/json';

        any ['get', 'post'] => '/books' => sub ($dancer) {
            my $schema = schema;

            my $result = [];
            # NOTE: paging is not covered here
            foreach my $book ( $schema->resultset('Book')->search( {} )->all ) {
                push (@$result, { $book->get_columns });
            }
            return to_json( $result );
        };

        any ['get', 'post'] => '/authors' => sub ($dancer) {
            my $schema = schema;

            my $result = [];
            # NOTE: paging is not covered here
            foreach my $author ( $schema->resultset('Author')->search( {} )->all ) {
                push (@$result, { $author->get_columns });
            }
            return to_json( $result );
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

            return to_json( $result );
        };

        del '/books/:id' => sub ($dancer) {
            my $id = int route_parameters->get('id');

            my $schema = schema;

            my $book = $schema->resultset('Book')->search( {id => $id} )->first;
            send_error("No such book with id [$id], nothing to delete.", 410) unless (defined $book);

            $book->delete;

            return to_json({ $id => 'OK deleted' });
        };

        get '/authors/:id' => sub ($dancer) {
            my $id = int route_parameters->get('id');

            my $schema = schema;
            my $result = {};

            my $author = $schema->resultset('Author')->search( {id => $id} )->first;
            send_error("Author with id [$id] not found!", 404) unless (defined $author);

            %$result = $author->get_columns;
            my @books_rs = $author->search_related('book_authors');
            my @book_ids;
            push (@book_ids, $_->book_id) foreach @books_rs;
            my @books = $schema->resultset('Book')->search( {id => [ @book_ids ]} )->all;
            push ($result->{book}->@*, { $_->get_columns }) foreach @books;

            return to_json( $result );
        };

        del '/authors/:id' => sub ($dancer) {
            my $id = int route_parameters->get('id');

            my $schema = schema;

            my $author = $schema->resultset('Author')->search( {id => $id} )->first;
            send_error("No such author with id [$id], nothing to delete.", 410) unless (defined $author);

            $author->delete;

            return to_json({ $id => 'OK deleted' });
        };

        put '/authors/:id' => sub ($dancer) {
            my $id = int route_parameters->get('id');
            my $post = from_json(request->body);
            # TODO: Validation/hydration/grooming of incoming data

            my $schema = schema;

            my $author = $schema->resultset('Author')->search( {id => $id} )->first;
            send_error("There is already an author with id [$id].", 409) if (defined $author);

            $author = $schema->resultset('Author');
            $author->create($post);

            status 201;
            return to_json({ $id => 'OK created' });
        };
    };

    1;
}

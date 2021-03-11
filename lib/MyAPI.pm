package MyAPI v0.0.2 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use Dancer2; no warnings 'experimental';
    use Dancer2::Plugin::DBIC;

    use MyModel;

    prefix '/api' if (${^RM} eq 'Dancer'); # it behaves differently in different run modes
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

    put '/books/:id' => sub ($dancer) {
        my $id = int route_parameters->get('id');
        my $post = from_json(request->body);
        $post->{id} = $id; # Prefer id from the request path

        $post = MyModel::As('book', $post);

        my $schema = schema;

        my $book = $schema->resultset('Book')->search( {id => $id} )->first;
        send_error("There is already a book with id [$id].", 409) if (defined $book);

        my $authors = delete $post->{author};
        if (defined $authors) {
            my $authors_rs = $schema->resultset('Author');
            my $book_authors_rs = $schema->resultset('BookAuthors');
            foreach (@$authors) {
                $authors_rs->find_or_create($_);
                $book_authors_rs->create({
                    book_id   => $_->{id},
                    author_id => $id,
                });
            }
        }

        $book = $schema->resultset('Book');
        $book->create($post);

        status 201;
        return to_json({ $id => 'OK created' });
    };

    patch '/books/:id' => sub ($dancer) {
        my $id = int route_parameters->get('id');
        my $post = from_json(request->body);

        # TODO: improve check
        MyModel::As('book', $post, -check);
        my $new_id = int $post->{id};

        my $schema = schema;

        my $book_rs = $schema->resultset('Book')->search( {id => $id} )->first;
        send_error("There is no book with id [$id].", 404) unless (defined $book_rs);

        my %book = $book_rs->get_columns;
        my @diff;
        foreach my $k (keys %book) {
            next unless (exists $post->{$k});
            next if ($post->{$k} eq $book{$k});
            push (@diff, $k, $post->{$k});
        }

        return to_json({ $id => 'Nothing to patch' }) unless (@diff);

        # TODO: Update book's id elsewhere
        my $target_book_rs = $schema->resultset('Book')->search( {id => $new_id} )->first;
        send_error("There is already a book with id [$new_id].", 409) if (defined $target_book_rs);
        $book_rs->update({ @diff });

        return to_json({ $id => 'OK patched' });
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
        $post->{id} = $id; # Prefer id from the request path
        $post = MyModel::As('author', $post);

        my $schema = schema;

        my $author = $schema->resultset('Author')->search( {id => $id} )->first;
        send_error("There is already an author with id [$id].", 409) if (defined $author);

        my $books = delete $post->{book};
        if (defined $books) {
            my $book_rs = $schema->resultset('Book');
            my $book_authors_rs = $schema->resultset('BookAuthors');
            foreach (@$books) {
                $book_rs->find_or_create($_);
                $book_authors_rs->create({
                    book_id   => $_->{id},
                    author_id => $id,
                });
            }
        }

        $author = $schema->resultset('Author');
        $author->create($post);

        status 201;
        return to_json({ $id => 'OK created' });
    };

    patch '/authors/:id' => sub ($dancer) {
        my $id = int route_parameters->get('id');
        my $post = from_json(request->body);

        # TODO: improve check
        MyModel::As('author', $post, -check);
        my $new_id = int $post->{id};

        my $schema = schema;

        my $author_rs = $schema->resultset('Author')->search( {id => $id} )->first;
        send_error("There is no author with id [$id].", 404) unless (defined $author_rs);

        my %author = $author_rs->get_columns;
        my @diff;
        foreach my $k (keys %author) {
            next unless (exists $post->{$k});
            next if ($post->{$k} eq $author{$k});
            push (@diff, $k, $post->{$k});
        }

        return to_json({ $id => 'Nothing to patch' }) unless (@diff);

        # TODO: Update author's id elsewhere
        my $target_author_rs = $schema->resultset('Author')->search( {id => $new_id} )->first;
        send_error("There is already an author with id [$new_id].", 409) if (defined $target_author_rs);
        $author_rs->update({ @diff });

        return to_json({ $id => 'OK patched' });
    };

    1;
}

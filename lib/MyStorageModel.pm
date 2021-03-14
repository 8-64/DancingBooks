# Data storage abstraction module - storage/retrieval/modification of data
package MyStorageModel v0.0.2 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use Dancer2; no warnings 'experimental';
    use Dancer2::Plugin::DBIC;
    use Text::CSV;

    use MyModel;

    sub GetBookInfo ($book, $schema) {
        my $result = {};
        %$result = $book->get_columns;

        my @authors = $schema->resultset('Author')->search(
             { id => { -in => $book->search_related('book_authors')->get_column('author_id')->as_query } }
        )->all;
        push ($result->{author}->@*, { $_->get_columns }) foreach @authors;
        $result;
    }

    sub GetAuthorInfo ($author, $schema) {
        my $result = {};
        %$result = $author->get_columns;

        my @books = $schema->resultset('Book')->search(
             { id => { -in => $author->search_related('book_authors')->get_column('book_id')->as_query } }
        )->all;
        push ($result->{book}->@*, { $_->get_columns }) foreach @books;
        $result;
    }

    sub LoadFromCSV ($source, $schema) {
        my $csv = Text::CSV->new;
        opendir(my $DATADIR, $source) or die ("Can't open the data dir [$source] - [$!]");
        while (my $item = readdir $DATADIR) {
            next if $item !~ /\.csv\z/;

            my $table = substr($item, 0, rindex($item, '.'));

            open (my $CSV, '<:encoding(utf-8)', "$source/$item") or die ("Can't open file[$source/$item] - [$!]");
            my $columns = $csv->getline($CSV);
            my (@entry, @extra_processing);
            foreach (@$columns) {
                my $extras = [];
                push (@$extras, \&MyModel::toInt)  if /id\z/i;
                push (@$extras, \&MyModel::toDate) if /date/i;
                push (@extra_processing, $extras);
            }

            while (my $row = $csv->getline($CSV)) {
                my @fields;
                while (my ($i, $cell) = each @$row) {
                    foreach ($extra_processing[$i]->@*) {
                        $cell = $_->($cell);
                    }
                    push (@fields, $columns->[$i], $cell);
                }

                $schema->resultset($table)->create({ @fields });
            }

            close $CSV;
        }
        closedir $DATADIR;
        1;
    }

    1;
}

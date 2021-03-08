package MySchema::Result::BookAuthors v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use parent 'DBIx::Class::Core';

    # Table
    __PACKAGE__->table('book_authors');

    # Columns
    __PACKAGE__->add_columns(
        book_id => {
            data_type => 'integer',
            is_foreign_key => 1,
            is_nullable => 0
        },
        author_id => {
            data_type => 'integer',
            is_foreign_key => 1,
            is_nullable => 0
        },
    );

    # Relations
    __PACKAGE__->belongs_to(
        authors => 'MySchema::Result::Author',
        { id => 'author_id' },
        { is_deferrable => 0, on_delete => 'NO ACTION', on_update => 'NO ACTION' },
    );
    __PACKAGE__->belongs_to(
        books => 'MySchema::Result::Book',
        { id => 'book_id' },
        { is_deferrable => 0, on_delete => 'NO ACTION', on_update => 'NO ACTION' },
    );

    1;
}

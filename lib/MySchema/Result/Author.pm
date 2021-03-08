package MySchema::Result::Author v0.0.1 {
    use v5.23;
    use feature ':all';
    use warnings;
    use utf8;

    use parent 'DBIx::Class::Core';

    # Table
    __PACKAGE__->table('authors');

    # Columns
    __PACKAGE__->add_columns(
        name => {
            data_type => 'varchar',
            size      => 100,
            is_nullable => 0
        },
        surname => {
            data_type => 'varchar',
            size      => 200,
            is_nullable => 1
        },
        country => {
            data_type => 'varchar',
            size      => 2,
            is_nullable => 1
        },
        id  => {
            data_type => 'integer',
            is_nullable => 0,
            is_auto_increment => 1,
        },
    );

    # Primary key
    __PACKAGE__->set_primary_key('id');

    # Relations
    __PACKAGE__->has_many(
        book_authors => 'MySchema::Result::BookAuthors',
        { "foreign.author_id" => "self.id" },
        { cascade_copy => 0, cascade_delete => 0 },
    );

    1;
}

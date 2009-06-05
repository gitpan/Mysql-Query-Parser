use strict;
use warnings;
use Mysql::Query::Parser;

use Data::Dumper;

use Test::More;
plan( tests => 13 );

my $query = Mysql::Query::Parser->new();

my $where_list = [
    "id = 'x'",
    "id > 18",
    "id >= 18",
    "id <= 18",
    "id2 < 18 and id3 > 10",
    "id2 < 18 or id3 > 10",
    "id2 < 18 and id3 > 10",
    "price between 1000 and 2000",
"start_date between '2009-06-10 00' AND '2009-06-15' AND end_date between '2009-10-10 00' AND '2009-10-15 00:00:00'",
"start_date between '2009-06-10 00' AND '2009-06-15 00:00' AND end_date between '2009-10-10 00' AND '2009-10-15 00:00:00'",
    "price is not null",
    "price is null",
    "NOT author IN ('auth_A', 'auth_C')",
    "author NOT IN ('auth_A', 'auth_C')"
];

my $data = {
    "id = 'x'" => {
        'where' => [
            {
                'mark'  => '=',
                'value' => '\'x\'',
                'key'   => 'id'
            }
        ]
    },
    "id > 18" => {
        'where' => [
            {
                'mark'  => '>',
                'value' => '18',
                'key'   => 'id'
            }
        ]
    },
    "id >= 18" => {
        'where' => [
            {
                'mark'  => '>=',
                'value' => '18',
                'key'   => 'id'
            }
        ]
    },
    "id <= 18" => {
        'where' => [
            {
                'mark'  => '<=',
                'value' => '18',
                'key'   => 'id'
            }
        ]
    },
    "id2 < 18 and id3 > 10" => {
        'and' => [
            {
                'mark'  => '<',
                'value' => '18',
                'key'   => 'id2'
            },
            {
                'mark'  => '>',
                'value' => '10',
                'key'   => 'id3'
            }
        ]
    },
    "id2 < 18 or id3 > 10" => {
        'or' => [
            {
                'mark'  => '<',
                'value' => '18',
                'key'   => 'id2'
            },
            {
                'mark'  => '>',
                'value' => '10',
                'key'   => 'id3'
            }
        ]
    },
    "id2 < 18 and id3 > 10" => {
        'and' => [
            {
                'mark'  => '<',
                'value' => '18',
                'key'   => 'id2'
            },
            {
                'mark'  => '>',
                'value' => '10',
                'key'   => 'id3'
            }
        ]
    },
    "price between 1000 and 2000" => { 'where_between' => { '1' => { 'price' => [ '1000', '2000' ] } } },

    "start_date between '2009-06-10 00' AND '2009-06-15' AND end_date between '2009-10-10 00' AND '2009-10-15 00:00:00'" => {
        'where_between' => {
            '1' =>
              { 'start_date' => [ '\'2009-06-10 00\'', '\'2009-06-15\' ' ] },
            '2' => {
                'end_date' => [ '\'2009-10-10 00\'', '\'2009-10-15 00:00:00\'' ]
            }
        }
    },
    "start_date between '2009-06-10 00' AND '2009-06-15 00:00' AND end_date between '2009-10-10 00' AND '2009-10-15 00:00:00'" => {
        'where_between' => {
            '1' => {
                'start_date' => [ '\'2009-06-10 00\'', '\'2009-06-15 00:00\'' ]
            },
            '2' => {
                'end_date' => [ '\'2009-10-10 00\'', '\'2009-10-15 00:00:00\'' ]
            }
        }
    },
    "price is not null" => {
        'where' => [
            {
                'mark' => 'IS NOT NULL',
                'key'  => 'price'
            }
        ]
    },
    "price is null" => {
        'where' => [
            {
                'mark' => 'IS NULL',
                'key'  => 'price'
            }
        ]
    },
    "NOT author IN ('auth_A', 'auth_C')" => {
        'where' => [
            {
                'mark'   => 'NOT IN',
                'value1' => 'auth_A',
                'value2' => 'auth_C',
                'key'    => 'authOR'
            }
        ]
    },
    "author NOT IN ('auth_A', 'auth_C')" => {
        'where' => [
            {
                'mark'   => 'NOT IN',
                'value1' => 'auth_A',
                'value2' => 'auth_C',
                'key'    => 'authOR'
            }
        ]
    },
};

{
    foreach my $key ( keys %$data ){
        my $where_info = $query->_split_where_parts($key);
        is_deeply( $where_info,  $data->{$key}, 'split where parts check' );
    }
}


1;

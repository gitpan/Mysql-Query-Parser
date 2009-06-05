use strict;
use warnings;
use Mysql::Query::Parser;

use Data::Dumper;

use Test::More tests => 7;

my $query = Mysql::Query::Parser->new();

my $data = {
    "id2 < 18" => {
      'mark' => '<',
      'value' => '18',
      'key' => 'id2'
    },
    "id2 =< 18" => {
      'mark' => '=<',
      'value' => '18',
      'key' => 'id2'
    },
     "comments LIKE '%excellen%'" => {
          'mark' => 'LIKE',
          'value' => '\'%excellen%\'',
          'key' => 'comments'
    },
    "title IS NOT NULL" => {
          'mark' => 'IS NOT NULL',
          'key' => 'title'
    },
    "title IS NULL" => {
          'mark' => 'IS NULL',
          'key' => 'title'
    },
    "author NOT IN ('auth01', 'auth02')" => {
          'mark' => 'NOT IN',
          'value1' => 'auth01',
          'value2' => 'auth02',
          'key' => 'author'
    },
    "NOT author IN ('auth0002', 'auth0003')" => {
          'mark' => 'NOT IN',
          'value1' => 'auth0002',
          'value2' => 'auth0003',
          'key' => 'author'
    },
};

foreach my $key ( keys %$data ){
    my $where_info = $query->_where_parts_conditional_check($key);
    is_deeply( $where_info,  $data->{$key}, 'where_parts check' );
}

1;



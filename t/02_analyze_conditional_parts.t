use strict;
use warnings;
use Mysql::Query::Parser;

use Data::Dumper;

use Test::More;
plan( tests => 10 );

my $query = Mysql::Query::Parser->new();

my $data = {
    "table_name limit 10" => {
        'table' => ['table_name '],
        'limit' => '10'
    },
    "table01, table02, table03 limit 10" => {
        'table' => [ 'table01', 'table02', 'table03' ],
        'limit' => '10'
    },
    "table_name order by user_id limit 10" => {
        'table'    => ['table_name '],
        'order_by' => 'user_id ',
        'limit'    => '10'
    },
    "table_name order by user_id desc limit 10" => {
        'table'    => ['table_name '],
        'order_by' => 'user_id desc ',
        'limit'    => '10'
    },
    "table_name group by log_date,check_date order by user_id desc limit 10" =>
      {
        'table'    => ['table_name '],
        'order_by' => 'user_id desc ',
        'group_by' => 'log_date,check_date ',
        'limit'    => '10'
      },
"table_name where id > 20 group by log_date,check_date order by user_id desc limit 10"
      => {
        'table'    => ['table_name '],
        'order_by' => 'user_id desc ',
        'group_by' => 'log_date,check_date ',
        'limit'    => '10',
        'where'    => {
            'where' => [
                {
                    'mark'  => '>',
                    'value' => '20',
                    'key'   => 'id'
                }
            ]
        }
      },
"table_name where id > 20 and id2 < 200 group by log_date,check_date order by user_id desc limit 10"
      => {
        'table'    => [ 'table_name '],
        'order_by' => 'user_id desc ',
        'group_by' => 'log_date,check_date ',
        'limit'    => '10',
        'where'    => {
            'and' => [
                {
                    'mark'  => '>',
                    'value' => '20',
                    'key'   => 'id'
                },
                {
                    'mark'  => '<',
                    'value' => '200',
                    'key'   => 'id2'
                }
            ]
        }
      },
"table_name where start_date between A and B and id2 < 200 group by log_date,check_date order by user_id desc limit 10"
      => {
        'table'    => [ 'table_name ' ],
        'order_by' => 'user_id desc ',
        'group_by' => 'log_date,check_date ',
        'limit'    => '10',
        'where'    => {
            'where' => [
                {
                    'mark'  => '<',
                    'value' => '200',
                    'key'   => 'id2'
                }
            ],
            'where_between' => { '1' => { 'start_date' => [ 'A', 'B ' ] } }
        }
      },
"table01 inner join table02 on ( table01.id = table02.id ) where start_date between A and B and id2 < 200 group by log_date,check_date order by user_id desc limit 10"
      => {
        'table'    => [ 'table01', 'table02' ],
        'order_by' => 'user_id desc ',
        'group_by' => 'log_date,check_date ',
        'limit'    => '10',
        'join'     => {
            'table02' => {
                'type' => 'INNER JOIN',
                'case' => '( table01.id = table02.id )'
            }
        },
        'where' => {
            'where' => [
                {
                    'mark'  => '<',
                    'value' => '200',
                    'key'   => 'id2'
                }
            ],
            'where_between' => { '1' => { 'start_date' => [ 'A', 'B ' ] } }
        }
      },
"table01 left join table02 on ( table01.id = table02.id ) left join table03 on ( table01.id = table03.id ) where start_date between A and B and id2 < 200 group by log_date,check_date order by user_id desc limit 10"
      => {
        'table'    => [ 'table01', 'table02', 'table03' ],
        'order_by' => 'user_id desc ',
        'group_by' => 'log_date,check_date ',
        'limit'    => '10',
        'join'     => {
            'table02' => {
                'type' => 'LEFT JOIN',
                'case' => '( table01.id = table02.id )'
            },
            'table03' => {
                'type' => 'LEFT JOIN',
                'case' => '( table01.id = table03.id )'
            }
        },
        'where' => {
            'where' => [
                {
                    'mark'  => '<',
                    'value' => '200',
                    'key'   => 'id2'
                }
            ],
            'where_between' => { '1' => { 'start_date' => [ 'A', 'B ' ] } }
        }
      },
};

foreach my $key ( keys %$data ) {
    my $result = $query->_analyze_conditional_parts($key);
    is_deeply( $result,  $data->{$key}, 'analyze_conditional_parts($key) check' );
}

1;

use strict;
use warnings;
use Mysql::Query::Parser;

use Data::Dumper;

use Test::More;
plan( tests => 4 );

my $query = Mysql::Query::Parser->new();

{
    my $sql    = 'select * from table01';
    my $result = $query->analyze_query($sql);
    my $dummy  = {
        'info'    => { 'table' => ['table01'] },
        'columns' => '*'
    };
    is_deeply( $result, $dummy, 'analyze sql 01' );
}

{
    my $sql    = 'select id, names from table02 order by names';
    my $result = $query->analyze_query($sql);

    my $dummy = {
        'info' => {
            'table'    => ['table02 '],
            'order_by' => 'names'
        },
        'columns' => [ 'id', ' names' ]
    };
    is_deeply( $result, $dummy, 'analyze sql 02' );
}

{
    my $sql =
'select * from table01 inner join table02 on ( table01.id = table02.id ) group by logdate,chk_flag';
    my $result = $query->analyze_query($sql);

    my $dummy = {
        'info' => {
            'table'    => [ 'table01', 'table02' ],
            'group_by' => 'logdate,chk_flag',
            'join'     => {
                'table02' => {
                    'type' => 'INNER JOIN',
                    'case' => '( table01.id = table02.id )'
                }
            }
        },
        'columns' => '*'
    };
    is_deeply( $result, $dummy, 'analyze sql 03' );
}

{
    my $sql =
'select * from table01 inner join table02 on ( table01.id = table02.id ) inner join table03 on ( table01.id = table03.id )  group by logdate,chk_flag';
    my $result = $query->analyze_query($sql);

    my $dummy = {
        'info' => {
            'table'    => [ 'table01', 'table02', 'table03' ],
            'group_by' => 'logdate,chk_flag',
            'join'     => {
                'table02' => {
                    'type' => 'INNER JOIN',
                    'case' => '( table01.id = table02.id )'
                },
                'table03' => {
                    'type' => 'INNER JOIN',
                    'case' => '( table01.id = table03.id )'
                }
            }
        },
        'columns' => '*'
    };

    is_deeply( $result, $dummy, 'analyze sql 04' );
}

1;

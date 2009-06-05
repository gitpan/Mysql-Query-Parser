package Mysql::Query::Parser;

use strict;
use warnings;

our $VERSION = '0.00001_00';

sub new {
    my $class = shift;
    my $self  = {};
    return bless $self, $class;
}

sub analyze_query {
    my $self = shift;
    my $sql  = shift;

    ## normalize
    $sql =~ s/^\s*//;
    $sql =~ s/\s*$//;
    $sql =~ s/[\r\n]/ /g;
    $sql =~ s/\s+/ /g;

    my $table_info = {};

    my @tables = ();
    if ( $sql =~ /select\s+(.*)\s+from\s+(.*)/i ) {
        my $sql_after_from = $2;

        $table_info->{info} =
          $self->_analyze_conditional_parts($sql_after_from);

        $table_info->{columns} = $self->_check_columns($1);
    }

    return $table_info;
}

sub _analyze_conditional_parts {
    my $self = shift;
    my $str  = shift;

    my $option = {};

    ## normalize
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    $str =~ s/[\r\n]/ /g;
    $str =~ s/\s+/ /g;

    ## between parts
    $str =~ s/join/JOIN/g;
    $str =~ s/inner/INNER/g;
    $str =~ s/outer/OUTER/g;
    $str =~ s/left/LEFT/g;
    $str =~ s/right/RIGHT/g;

    my $convert_string = $str; 

    ## 1. analyze (limit)
    if ( $str =~ /^(.*)limit (10)/i ) {
        $convert_string = $1;
        $option->{limit} = $2;
    }

    ## 2. analyze (order by)
    if ( $convert_string =~ /^(.*)order\s+by\s+(.*)\s*\S*/i ) {
        $convert_string = $1;
        $option->{order_by} = $2;
    }

    ## 3. analyze(group by)
    if ( $convert_string =~ /^(.*)group\s+by\s+(.*)\s*/i ) {
        $convert_string = $1;
        $option->{group_by} = $2;
    }

    ## 4. analyze(where)
    if ( $convert_string =~ /(.*)where(.*)/ig ) {
        $convert_string = $1;
        my $where_string = $2;
        my $where_data   = $self->_split_where_parts($where_string);
        $option->{where} = $where_data;
    }

    my @join_tables = ();
    my $table_name  = undef;
    my $join_flag   = 0;
    my $count       = 0;

    ## Join parts
    while ( $convert_string =~
/(\S*)\s*(INNER|OUTER|LEFT|RIGHT) JOIN (\S+) on ([\(]*\s+\S+\s+=\s+\S+\s+[\)]*)(.*)/
      )
    {
        push( @join_tables, $1 ) if ( !$join_flag );

        my @list = split( /JOIN/, $4 );

        $option->{join}->{$3}->{type} = $2 . ' JOIN';
        $option->{join}->{$3}->{case} = $4;
        push( @join_tables, $3 ) if ($3);

        $convert_string = $5;
        $join_flag++;

    }
    $option->{table} = $table_name;

    if ( !$join_flag ) {
        if ( $convert_string =~ /\,/ ) {
            my @tables = split( /\,/, $convert_string );

            my @lists = ();
            foreach (@tables) {
                $_ =~ s/\s+//g;
                push( @lists, $_ );
            }
            $option->{table} = \@lists;
        }
        else {
            $option->{table}->[0] = $convert_string;
        }
    }
    else {
        $option->{table} = \@join_tables;
    }
    return ($option);
}

sub _split_where_parts {
    my $self = shift;
    my $str  = shift;

    ## normalize
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    $str =~ s/[\r\n]/ /g;
    $str =~ s/\s+/ /g;

    ## between parts
    $str =~ s/between/BETWEEN/g;
    $str =~ s/and/AND/g;
    $str =~ s/or/OR/g;

    my $data       = {};
    my $where_list = [];
    my $btwn_list = [];

    ## Between Block
    my $count = 0;
    while ( $str =~
        /^\s*[AND]*\s*(\S+)\s+between\s+(\S+\s*\S*)\s+AND\s+(\S+\s*\S*)(.*)$/i )
    {
        $count++;
        my $str1 = $1;
        my $str2 = $2;
        my $str3 = $3;
        my $str4 = $4;
        $str3 =~ s/AND//;

        push( @$btwn_list, $str2 );
        push( @$btwn_list, $str3 );

        $data->{where_between}->{$count}->{$str1} = $btwn_list;

        $str       = $str4;
        $btwn_list = [];
    }

    if ($str) {

        ## AND Block
        if ( $str =~ /AND/i ) {
            my @where_list = ();
            foreach ( split( 'AND', $str ) ) {
                my $where_info = $self->_where_parts_conditional_check($_);
                push( @$where_list, $where_info );
            }
            $data->{and} = $where_list;
            ## OR Block
        }
        elsif ( $str =~ /\s+OR\s+/i ) {
            my @where_list = ();
            foreach ( split( 'OR', $str ) ) {
                my $where_info = $self->_where_parts_conditional_check($_);
                push( @$where_list, $where_info );
            }
            $data->{or} = $where_list;
        }
        else {
            my $where_info = $self->_where_parts_conditional_check($str);
            push( @$where_list, $where_info );
            $data->{where} = $where_list;
        }
    }
    return $data;
}

sub _where_parts_conditional_check {
    my $self = shift;
    my $str  = shift;

    my $where_info = {};

    ## normalize
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    $str =~ s/[\r\n]/ /g;
    $str =~ s/\s+/ /g;

    ## where parts
    $str =~ s/is not null/IS NOT NULL/g;
    $str =~ s/is null/IS NULL/g;
    $str =~ s/not/NOT/g;
    $str =~ s/in/IN/g;
    $str =~ s/like/LIKE/g;

    if ( $str =~ /(\S+) IS NOT NULL/ ) {
        $where_info->{key}  = $1;
        $where_info->{mark} = 'IS NOT NULL';
    }
    elsif ( $str =~ /(\S+) IS NULL/ ) {
        $where_info->{key}  = $1;
        $where_info->{mark} = 'IS NULL';
    }
    elsif ( $str =~ /NOT (\S+) IN \('(\S+)', '(\S+)'\)/ ) {
        $where_info->{key}    = $1;
        $where_info->{mark}   = 'NOT IN';
        $where_info->{value1} = $2;
        $where_info->{value2} = $3;
    }
    elsif ( $str =~ /(\S+) NOT IN \('(\S+)', '(\S+)'\)/ ) {
        $where_info->{key}    = $1;
        $where_info->{mark}   = 'NOT IN';
        $where_info->{value1} = $2;
        $where_info->{value2} = $3;
    }
    elsif ( $str =~ /(\S+) IN \('(\S+)', '(\S+)'\)/ ) {
        $where_info->{key}    = $1;
        $where_info->{mark}   = 'IN';
        $where_info->{value1} = $2;
        $where_info->{value2} = $3;
        print "IN";
    }
    elsif ( $str =~ /(\S+)\s*(\S+)\s*(\S+)/ ) {
        $where_info->{key}   = $1;
        $where_info->{mark}  = $2;
        $where_info->{value} = $3;
    }
    return ($where_info);
}

sub _check_columns {
    my $self    = shift;
    my $columns = shift;

    if ( $columns eq '*' ) {
        return '*';
    }

    if ( $columns !~ /,/g ) {
        return $columns;
    }
    else {
        my @column_list = split( ',', $columns );
        return ( \@column_list );
    }
}

1;

__END__

=head1 NAME

Mysql::Query::Parser - The module which parse MYSQL query string.

=head1 SYNOPSIS

  use Mysql::Query::Parser;

  my $sql = 'select * from table01 inner join table02 on ( table01.id = table02.id ) inner join table03 on ( table01.id = table03.id ) group by logdate,chk_flag';
  my $result = $query->analyze_query($sql);

=head1 DESCRIPTION

Mysql::Query::Parser is The module which parse requests of MYSQL, and a result is returned.

=head1 AUTHOR

kazuhiko yamakura E<lt>yamakura@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<>

=cut

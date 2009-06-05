use inc::Module::Install;
name 'Mysql-Query-Parser';
all_from 'lib/Mysql/Query/Parser.pm';
build_requires 'Test::More';

use_test_base;
auto_install;
WriteAll;



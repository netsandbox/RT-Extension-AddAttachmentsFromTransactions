use inc::Module::Install;

RTx         'RT-Extension-AddAttachmentsFromTransactions';
all_from    'lib/RT/Extension/AddAttachmentsFromTransactions.pm';
readme_from;

repository 'https://github.com/cloos/RT-Extension-AddAttachmentsFromTransactions';

requires 'List::MoreUtils';

requires_rt '4.0.8';

no_index package => 'RT::Action::SendEmail';
no_index package => 'RT::Attachment';
no_index package => 'RT::Ticket';

my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";

substitute(
    {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
    },
    {
        sufix => '.in'
    },
    qw(lib/RT/Extension/AddAttachmentsFromTransactions/Test.pm),
);

sign;
WriteAll;

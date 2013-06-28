use inc::Module::Install;

RTx         'RT-Extension-AddAttachmentsFromTransactions';
all_from    'lib/RT/Extension/AddAttachmentsFromTransactions.pm';
readme_from;

requires 'List::MoreUtils';

requires_rt '4.0.8';

no_index package => 'RT::Action::SendEmail';
no_index package => 'RT::Ticket';

sign;
WriteAll;

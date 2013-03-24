use inc::Module::Install;

RTx         'RT-Extension-AddAttachmentsFromTransactions';
all_from    'lib/RT/Extension/AddAttachmentsFromTransactions.pm';
readme_from;

requires_rt '4.0.0';

WriteAll;

use inc::Module::Install;

RTx         'RT-Extension-AddAttachmentsFromTransactions';
all_from    'lib/RT/Extension/AddAttachmentsFromTransactions.pm';
readme_from;

requires('Hook::LexWrap');

WriteAll;

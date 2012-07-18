package RT::Extension::AddAttachmentsFromTransactions;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::AddAttachmentsFromTransactions - Add Attachments From Transactions

=head1 DESCRIPTION

With this plugin you can attach attachments from previous transactions to a
reply or comment.

Thanks to BÁLINT Bekény for contributing the code from his implementation.

Also Thanks to Best Practical Solutions who are working on this feature for
RT 4.2 on the '4.2/attach-from-transactions' branch where I've borrowed some
code for this extension.

=head1 INSTALLATION

Installation instructions for RT-Extension-AddAttachmentsFromTransactions:

	perl Makefile.PL
	make
	make install
	Add 'RT::Extension::AddAttachmentsFromTransactions' to @Plugins in /opt/rt3/etc/RT_SiteConfig.pm
	Clear mason cache: rm -rf /opt/rt3/var/mason_data/obj
	Restart webserver

=head1 AUTHOR

Christian Loos <cloos@netcologne.de>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2012, NetCologne GmbH. All Rights Reserved.

This extension is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://bestpractical.com/rt/>
L<http://www.gossamer-threads.com/lists/rt/users/107976>
L<https://github.com/bestpractical/rt/tree/4.2/attach-from-transactions>

=head1 THANKS

BÁLINT Bekény (Docca OutSource IT Ltd.)

Best Practical Solutions

=cut

use Hook::LexWrap;

use RT::Ticket;
wrap 'RT::Ticket::_RecordNote',
    pre => sub{
        my %args = @_[1..@_-2];

        # move the Attachment id's from session to the RT-Attach header
        for my $id ( @{ $HTML::Mason::Commands::session{'AttachExisting'} } ) {
            $args{'MIMEObj'}->head->add( 'RT-Attach' => $id );
        }
    };

1;

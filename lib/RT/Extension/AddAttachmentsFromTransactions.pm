package RT::Extension::AddAttachmentsFromTransactions;

use 5.008003;
use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '0.00_01';

use RT::Ticket;
my $orig_note = RT::Ticket->can('_RecordNote');
*RT::Ticket::_RecordNote = sub {
    my $self = shift;
    my %args = @_;

    # We can't do anything if we don't have an MIMEObj
    # so let the original method handle it
    return $orig_note->($self, %args) unless $args{'MIMEObj'};

    # move the Attachment id's from session to the RT-Attach header
    for my $id ( @{ $HTML::Mason::Commands::session{'AttachExisting'} } ) {
        $args{'MIMEObj'}->head->add( 'RT-Attach' => $id );
    }

    # cleanup session
    delete $HTML::Mason::Commands::session{'AttachExisting'};

    return $orig_note->($self, %args);
};

use RT::Action::SendEmail;
my $orig_add_attach = RT::Action::SendEmail->can('AddAttachments');
*RT::Action::SendEmail::AddAttachments = sub {
    my $self = shift;

    $orig_add_attach->($self, @_);

    $self->AddAttachmentsFromHeaders();
};

package RT::Action::SendEmail;

sub AddAttachmentsFromHeaders {
    my $self  = shift;
    my $orig  = $self->TransactionObj->Attachments->First;
    my $email = $self->TemplateObj->MIMEObj;

    use List::MoreUtils qw(uniq);

    # Add the RT-Attach headers from the transaction to the email
    if ($orig and $orig->GetHeader('RT-Attach')) {
        for my $id ($orig->ContentAsMIME(Children => 0)->head->get_all('RT-Attach')) {
            $email->head->add('RT-Attach' => $id);
        }
    }

    # Take all RT-Attach headers and add the attachments to the outgoing mail
    for my $id (uniq $email->head->get_all('RT-Attach')) {
        $id =~ s/(?:^\s*|\s*$)//g;

        my $attach = RT::Attachment->new( $self->TransactionObj->CreatorObj );
        $attach->Load($id);
        next unless $attach->Id
                and $attach->TransactionObj->CurrentUserCanSee;

        if ( !$email->is_multipart ) {
            $email->make_multipart( 'mixed', Force => 1 );
        }
        $self->AddAttachment($attach, $email);
    }
}

=encoding utf8

=head1 NAME

RT::Extension::AddAttachmentsFromTransactions - Add Attachments From Transactions

=head1 DESCRIPTION

With this plugin you can attach attachments from previous transactions to a
reply or comment.

=head1 INSTALLATION

=over

=item perl Makefile.PL

=item make

=item make install

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Set(@Plugins, qw(RT::Extension::AddAttachmentsFromTransactions));

or add C<RT::Extension::AddAttachmentsFromTransactions> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj/*

=item Restart your webserver

=back

=head1 AUTHOR

Christian Loos <cloos@netsandbox.de>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2012-2013, Christian Loos.

This extension is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item L<http://bestpractical.com/rt/>

=item L<http://www.gossamer-threads.com/lists/rt/users/107976>

=item L<https://github.com/bestpractical/rt/tree/4.2/attach-from-transactions>

=back

=head1 THANKS

Thanks to BÁLINT Bekény for contributing the code from his implementation.

Also Thanks to Best Practical Solutions who are working on this feature for
RT 4.2 on the '4.2/attach-from-transactions' branch where I've borrowed some
code for this extension.

=cut

1;

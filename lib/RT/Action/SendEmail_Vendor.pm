use strict;
no warnings qw(redefine);

package RT::Action::SendEmail;

# NOTE: AddAttachments method from 4.0-trunk
sub AddAttachments {
    my $self = shift;

    my $MIMEObj = $self->TemplateObj->MIMEObj;

    $MIMEObj->head->delete('RT-Attach-Message');

    my $attachments = RT::Attachments->new( RT->SystemUser );
    $attachments->Limit(
        FIELD => 'TransactionId',
        VALUE => $self->TransactionObj->Id
    );

    # Don't attach anything blank
    $attachments->LimitNotEmpty;
    $attachments->OrderBy( FIELD => 'id' );

    # We want to make sure that we don't include the attachment that's
    # being used as the "Content" of this message" unless that attachment's
    # content type is not like text/...
    my $transaction_content_obj = $self->TransactionObj->ContentObj;

    if (   $transaction_content_obj
        && $transaction_content_obj->ContentType =~ m{text/}i )
    {
        # If this was part of a multipart/alternative, skip all of the kids
        my $parent = $transaction_content_obj->ParentObj;
        if ($parent and $parent->Id and $parent->ContentType eq "multipart/alternative") {
            $attachments->Limit(
                ENTRYAGGREGATOR => 'AND',
                FIELD           => 'parent',
                OPERATOR        => '!=',
                VALUE           => $parent->Id,
            );
        } else {
            $attachments->Limit(
                ENTRYAGGREGATOR => 'AND',
                FIELD           => 'id',
                OPERATOR        => '!=',
                VALUE           => $transaction_content_obj->Id,
            );
        }
    }

    # attach any of this transaction's attachments
    my $seen_attachment = 0;
    while ( my $attach = $attachments->Next ) {
        if ( !$seen_attachment ) {
            $MIMEObj->make_multipart( 'mixed', Force => 1 );
            $seen_attachment = 1;
        }
        $self->AddAttachment($attach);
    }

    # NOTE: call the new method AddAttachmentsFromSession
    $self->AddAttachmentsFromSession();

    # NOTE: call the new method AddAttachmentsFromHeaders
    $self->AddAttachmentsFromHeaders();

}

# NOTE: new AddAttachmentsFromSession method
sub AddAttachmentsFromSession {
    my $self = shift;
    my $email = $self->TemplateObj->MIMEObj;

    # move the Attachment id's from session to the RT-Attach header
    for my $id ( @{ $HTML::Mason::Commands::session{'AttachExisting'} } ) {
        $email->head->add('RT-Attach' => $id);
    }
}

# NOTE: new AddAttachmentsFromHeaders method from 4.2/attach-from-transactions branch
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

1;

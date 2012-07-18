use strict;
use warnings;

package RT::Attachment;

# NOTE: new GetAllHeaders method from 4.2/attach-from-transactions branch
sub GetAllHeaders {
    my $self = shift;
    my $tag = shift;
    my @values = ();
    foreach my $line ($self->_SplitHeaders) {
        next unless $line =~ /^\Q$tag\E:\s+(.*)$/si;
        push @values, $1;
    }
    return @values;
}

1;

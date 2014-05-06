class Net::XMPP;

use Net::DNS;
use XML;

has $!socket;
has $.jid;
has $.jid-local;
has $.jid-domain;
has $.jid-resource;

method new(:$jid!, :$server, :$port = 5222, :$socket) {
    self.bless(:$jid, :$server, :$port, :$socket);
}

submethod BUILD(:$!jid, :$server, :$port, :$!socket){
    ($!jid-local, $!jid-domain) = $!jid.split("@");
    unless $!socket {
        if $server {
            $!socket = IO::Socket::INET.new(:host($server), :$port);
        } else {
            my $resolver = Net::DNS.new("8.8.8.8");
            my @records = $resolver.lookup('SRV', $!jid-domain);
            if @records {
                @records = @records.sort(*.priority <=> *.priority);
                $!socket = IO::Socket::INET.new(:host(@records[0].Str),
                                                :port(@records[0].port));
            } else {
                $!socket = IO::Socket::INET.new(:host($!jid-domain), :$port);
            }
        }
    }
    self!do-negotiation;
}

method !do-negotiation {
    my $done = False;
    until $done {
        self!start-streams;
        my $xml = self!get-stanza;
        unless $xml.root.name eq 'stream:features' {
            die "confused";
        }

        for $xml.root.nodes -> $feature {
            if $feature.name eq 'mechanisms' {
                die "Mechanisms NYI";
                #...
            } elsif $feature.name eq 'bind' {
                die "Bind NYI";
                #...
                $done = True;
            } elsif $feature.nodes[0] && $feature.nodes[0].name eq 'required' {
                die "Can't do feature '{$feature.name}', yet it is required";
            } else {
                # everything left looks optional
                $done = True;
            }
        }
    }
}

method !start-streams {
    # send our stream open
    $!socket.send("<?xml version='1.0'?>\n");
    $!socket.send("<stream:stream\n"
                 ~" from='$!jid'\n"
                 ~" to='$!jid-domain'\n"
                 ~" version='1.0'\n"
                 ~" xml:lang='en'\n"
                 ~" xmlns='jabber:client'\n"
                 ~" xmlns:stream='http://etherx.jabber.org/streams'>\n");

    # get server stream startup
    my $check = "<?xml version='1.0'?>";
    my $check2 ="<?xml version=\"1.0\"?>";
    my $xmlv = $!socket.recv($check.chars);
    unless $xmlv eq $check|$check2 {
        die "...";
    }

    my $buffer;
    my $last;
    while $last ne '>' {
        $last = $!socket.recv(1);
        $buffer ~= $last;
    }

    say $buffer;
    
    my $xml = from-xml($buffer ~ "</stream:stream>");
    # check things...
}

method !get-stanza {
    my $stanza;
    my $line;
    loop {
        $line = '';
        while $line ne '>' {
            $line = $!socket.recv(1);
            $stanza ~= $line;
        }

        if $stanza ~~ /^\s*\<\/stream\:stream\>/ {
            die "Connection closed";
        }

        try {
            my $xml = from-xml($stanza);
            say $stanza;
            return $xml;
        }
    }
}

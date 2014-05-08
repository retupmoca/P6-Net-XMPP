class Net::XMPP::IQ;

has $.type;
has $.id;
has @.body;

method Str {
    return "<iq id='$.id' type='$.type'>" ~ $.body ~ "</iq>";
}

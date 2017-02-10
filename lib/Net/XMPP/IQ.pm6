unit class Net::XMPP::IQ;

has $.from = '';
has $.to = '';
has $.type = '';
has $.id = '';
has @.body;

method Str {
    return "<iq { $.from ?? "from='$.from'" !! '' } { $.to ?? "to='$.to'" !! '' } id='$.id' type='$.type'>" ~ (@.body.map({~$_}).join) ~ "</iq>";
}

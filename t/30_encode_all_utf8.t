# $Id: 31_encode_to_ascii.t 25 2007-09-08 23:30:47Z cfaerber $

use utf8;
use strict;

use Test::More tests => 29;
use Net::IDN::Encode;

is(Net::IDN::Encode::_to_ascii('faerber'),'faerber');
is(Net::IDN::Encode::_to_ascii('xn--frber-gra'),'xn--frber-gra');
is(Net::IDN::Encode::_to_ascii('färber'),'xn--frber-gra');
is(Net::IDN::Encode::_to_ascii('中央大学'),'xn--fiq80yua78t');

is(Net::IDN::Encode::_to_unicode('faerber'),'faerber');
is(Net::IDN::Encode::_to_unicode('xn--frber-gra'),'färber');
is(Net::IDN::Encode::_to_unicode('xn--frber-gra'),'färber');
is(Net::IDN::Encode::_to_unicode('xn--fiq80yua78t'),'中央大学');

is(domain_to_ascii('faerber.muc.de'),'faerber.muc.de');
is(domain_to_ascii('xn--frber-gra.muc.de'),'xn--frber-gra.muc.de');
is(domain_to_ascii('färber.muc.de'),'xn--frber-gra.muc.de');
is(domain_to_ascii('中央大学.tw'),'xn--fiq80yua78t.tw');

is(domain_to_unicode('faerber.muc.de'),'faerber.muc.de');
is(domain_to_unicode('xn--frber-gra.muc.de'),'färber.muc.de');
is(domain_to_unicode('xn--frber-gra.muc.de'),'färber.muc.de');
is(domain_to_unicode('xn--fiq80yua78t.tw'),'中央大学.tw');

is(email_to_ascii('claus@faerber.muc.de'),'claus@faerber.muc.de');
is(email_to_ascii('claus@xn--frber-gra.muc.de'),'claus@xn--frber-gra.muc.de');
is(email_to_ascii('claus@färber.muc.de'),'claus@xn--frber-gra.muc.de');
is(email_to_ascii('test＠中央大学.tw'),'test@xn--fiq80yua78t.tw');
is(email_to_ascii(''), undef);
is(email_to_ascii('test'), 'test');

is(email_to_unicode('claus@faerber.muc.de'),'claus@faerber.muc.de');
is(email_to_unicode('claus＠faerber.muc.de'),'claus@faerber.muc.de');
is(email_to_unicode('claus@xn--frber-gra.muc.de'),'claus@färber.muc.de');
is(email_to_unicode('claus＠xn--frber-gra.muc.de'),'claus@färber.muc.de');
is(email_to_unicode('test@xn--fiq80yua78t.tw'),'test@中央大学.tw');
is(email_to_unicode(''),undef);
is(email_to_unicode('test'),'test');

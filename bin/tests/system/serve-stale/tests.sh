#!/bin/sh
#
# Copyright (C) 2017  Internet Systems Consortium, Inc. ("ISC")
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

SYSTEMTESTTOP=..
. $SYSTEMTESTTOP/conf.sh

RNDCCMD="$RNDC -c $SYSTEMTESTTOP/common/rndc.conf -p 9953 -s"

status=0
n=0

#echo "I:check ans.pl server ($n)"
#$DIG -p 5300 @10.53.0.2 example NS
#$DIG -p 5300 @10.53.0.2 example SOA
#$DIG -p 5300 @10.53.0.2 ns.example A
#$DIG -p 5300 @10.53.0.2 ns.example AAAA
#$DIG -p 5300 @10.53.0.2 txt enable
#$DIG -p 5300 @10.53.0.2 txt disable
#$DIG -p 5300 @10.53.0.2 ns.example AAAA
#$DIG -p 5300 @10.53.0.2 txt enable
#$DIG -p 5300 @10.53.0.2 ns.example AAAA
##$DIG -p 5300 @10.53.0.2 data.example TXT
#$DIG -p 5300 @10.53.0.2 nodata.example TXT
#$DIG -p 5300 @10.53.0.2 nxdomain.example TXT

n=`expr $n + 1`
echo "I:prime cache data.example ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 data.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:prime cache nodata.example ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nodata.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:prime cache nxdomain.example ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nxdomain.example TXT > dig.out.test$n
grep "status: NXDOMAIN" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:disable responses from authoritative server ($n)"
ret=0
$DIG -p 5300 @10.53.0.2 txt disable  > dig.out.test$n
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
grep "TXT.\"0\"" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

sleep 1

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: on (stale-answer-ttl=1 max-stale-ttl=3600)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale data.example ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 data.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nodata.example ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nodata.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nxdomain.example ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nxdomain.example TXT > dig.out.test$n
grep "status: NXDOMAIN" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:running 'rndc serve-stale off' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale off || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: off (rndc) (stale-answer-ttl=1 max-stale-ttl=3600)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale data.example (serve-stale off) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 data.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nodata.example (serve-stale off) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nodata.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nxdomain.example (serve-stale off) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nxdomain.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:running 'rndc serve-stale on' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale on || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: on (rndc) (stale-answer-ttl=1 max-stale-ttl=3600)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale data.example (serve-stale on) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 data.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nodata.example (serve-stale on) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nodata.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nxdomain.example (serve-stale on) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nxdomain.example TXT > dig.out.test$n
grep "status: NXDOMAIN" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:running 'rndc serve-stale no' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale no || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: off (rndc) (stale-answer-ttl=1 max-stale-ttl=3600)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale data.example (serve-stale no) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 data.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nodata.example (serve-stale no) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nodata.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nxdomain.example (serve-stale no) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nxdomain.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:running 'rndc serve-stale yes' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale yes || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: on (rndc) (stale-answer-ttl=1 max-stale-ttl=3600)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale data.example (serve-stale yes) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 data.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nodata.example (serve-stale yes) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nodata.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nxdomain.example (serve-stale yes) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nxdomain.example TXT > dig.out.test$n
grep "status: NXDOMAIN" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:running 'rndc serve-stale off' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale off || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:running 'rndc serve-stale reset' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale reset || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: on (stale-answer-ttl=1 max-stale-ttl=3600)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale data.example (serve-stale reset) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 data.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nodata.example (serve-stale reset) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nodata.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check stale nxdomain.example (serve-stale reset) ($n)"
ret=0
$DIG -p 5300 @10.53.0.1 nxdomain.example TXT > dig.out.test$n
grep "status: NXDOMAIN" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:running 'rndc serve-stale off' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale off || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: off (rndc) (stale-answer-ttl=1 max-stale-ttl=3600)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:updating ns1/named.conf ($n)"
ret=0
cp -f ns1/named2.conf ns1/named.conf || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:running 'rndc reload' ($n)"
ret=0
$RNDCCMD 10.53.0.1 reload > rndc.out.test$n 2>&1 || ret=1
grep "server reload successful" rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: off (rndc) (stale-answer-ttl=2 max-stale-ttl=7200)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale > rndc.out.test$n 2>&1 && ret=1
grep "unexpected end of input" rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale unknown' ($n)"
ret=0
$RNDCCMD 10.53.0.1 serve-stale unknown > rndc.out.test$n 2>&1 && ret=1
grep "syntax error" rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:enable responses from authoritative server ($n)"
ret=0
$DIG -p 5300 @10.53.0.2 txt enable  > dig.out.test$n
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
grep "TXT.\"1\"" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:prime cache data.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 data.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:prime cache nodata.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 nodata.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:prime cache nxdomain.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 nxdomain.example TXT > dig.out.test$n
grep "status: NXDOMAIN" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:disable responses from authoritative server ($n)"
ret=0
$DIG -p 5300 @10.53.0.2 txt disable  > dig.out.test$n
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
grep "TXT.\"0\"" dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

sleep 1

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.3 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: off (stale-answer-ttl=1 max-stale-ttl=604800)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check fail of data.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 data.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check fail of nodata.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 nodata.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check fail of nxdomain.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 nxdomain.example TXT > dig.out.test$n
grep "status: SERVFAIL" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale on' ($n)"
ret=0
$RNDCCMD 10.53.0.3 serve-stale on > rndc.out.test$n 2>&1 || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check 'rndc serve-stale status' ($n)"
ret=0
$RNDCCMD 10.53.0.3 serve-stale status > rndc.out.test$n 2>&1 || ret=1
grep '_default: on (rndc) (stale-answer-ttl=1 max-stale-ttl=604800)' rndc.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check data.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 data.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 1," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check nodata.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 nodata.example TXT > dig.out.test$n
grep "status: NOERROR" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

n=`expr $n + 1`
echo "I:check nxdomain.example (max-stale-ttl default) ($n)"
ret=0
$DIG -p 5300 @10.53.0.3 nxdomain.example TXT > dig.out.test$n
grep "status: NXDOMAIN" dig.out.test$n > /dev/null || ret=1
grep "ANSWER: 0," dig.out.test$n > /dev/null || ret=1
if [ $ret != 0 ]; then echo "I:failed"; fi
status=`expr $status + $ret`

echo "I:exit status: $status"
[ $status -eq 0 ] || exit 1

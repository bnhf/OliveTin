#!/usr/bin/env python3
# -*- coding: utf8 -*-
from __future__ import unicode_literals

"""
author: luapmartin
description: a really straight forward, quick and dirty iCal to xmltv converter
"""

import icalendar
import recurring_ical_events
from xmltv import xmltv_helpers
from xmltv.models import xmltv
from pathlib import Path
import sys
from datetime import date, datetime, timedelta
import requests

xmltv_file = Path("./basic.xml")

url = sys.argv[1]
channel_id = sys.argv[2]

channel = None
tv = xmltv.Tv()
my_cal = icalendar.Calendar.from_ical(requests.get(url).text)
now = datetime.now()
range_start = now - timedelta(days=1)
range_end = now + timedelta(days=14)

def record_event(e):
    start_time = e.get("DTSTART")
    if start_time:
        start_time = start_time.dt
    end_time = e.get("DTEND")
    if end_time:
        end_time = end_time.dt
    else:
        # if there is no end time the end time is set as the start time
        end_time = start_time
    summary = e.get("SUMMARY").title()
    description = e.get("DESCRIPTION")
    if description:
        description = description.title()
    program = xmltv.Programme(
        channel=channel_id,
        start=start_time.strftime('%Y%m%d%H%M%S %z'),
        stop=end_time.strftime('%Y%m%d%H%M%S %z'),
        sub_title=description,
        episode_num=xmltv.EpisodeNum(
            system="original-air-date",
            content=[start_time.strftime("%Y-%m-%d")]
        ),
        title=summary
    )
    tv.programme.append(program)


for a_program in my_cal.walk():
    if not channel:
        channel = xmltv.Channel(
            id=channel_id,
            display_name=[a_program.get("X-WR-CALNAME").title()]
        )
        tv.channel.append(channel)
        continue
    if a_program.get("TZID") or a_program.get("TZNAME"):
        # skip the lines about timezone information
        continue
    start_time = a_program.get("DTSTART")
    if start_time:
        start_time = start_time.dt
        if isinstance(start_time, datetime):
            if start_time < range_start.astimezone():
                # skip the events that are too old
                continue
        elif isinstance(start_time, date):
            if start_time < range_start.date():
                # skip the events that are too old
                continue
        else:
            continue
    else:
        continue
    record_event(a_program)

events = recurring_ical_events.of(my_cal).between(range_start, range_end)
for e in events:
    record_event(e)

xmltv_helpers.write_file_from_xml(xmltv_file, tv)

"""
# example of iCal data parsed :
ical_file = open("../res/basic.ics", 'rb')
C = icalendar.Calendar.from_ical(ical_file.read())
for a in C.walk():
    for k,v in a.items():
        print k,v
    print "-"*20

# as we can see first lines are descriptive

PRODID -//Google Inc//Google Calendar 70.9054//EN
VERSION 2.0
CALSCALE GREGORIAN
METHOD PUBLISH
X-WR-CALNAME TWiT Live Schedule
X-WR-TIMEZONE America/Los_Angeles
X-WR-CALDESC Schedule of upcoming live broadcasts on http://twit.tv and http://live.twit.tv. Updated regularly.
--------------------
TZID America/Los_Angeles
X-LIC-LOCATION America/Los_Angeles
--------------------
TZOFFSETFROM <icalendar.prop.vUTCOffset object at 0x7f6e6e46da50>
TZOFFSETTO <icalendar.prop.vUTCOffset object at 0x7f6e6cc75610>
TZNAME PDT
DTSTART <icalendar.prop.vDDDTypes object at 0x7f6e6cc758d0>
RRULE vRecur({u'BYMONTH': [3], u'FREQ': [u'YEARLY'], u'BYDAY': [u'2SU']})
--------------------
TZOFFSETFROM <icalendar.prop.vUTCOffset object at 0x7f6e6cc75810>
TZOFFSETTO <icalendar.prop.vUTCOffset object at 0x7f6e6cc75910>
TZNAME PST
DTSTART <icalendar.prop.vDDDTypes object at 0x7f6e6cc75990>
RRULE vRecur({u'BYMONTH': [11], u'FREQ': [u'YEARLY'], u'BYDAY': [u'1SU']})
--------------------
DTSTART <icalendar.prop.vDDDTypes object at 0x7f6e6cde5450>
DTEND <icalendar.prop.vDDDTypes object at 0x7f6e6cc759d0>
DTSTAMP <icalendar.prop.vDDDTypes object at 0x7f6e6cd8e950>
UID enol3dbcud5rlmbsd95cuqoqog@google.com
RECURRENCE-ID <icalendar.prop.vDDDTypes object at 0x7f6e6cc75b50>
CREATED <icalendar.prop.vDDDTypes object at 0x7f6e6cc75b10>
DESCRIPTION 
LAST-MODIFIED <icalendar.prop.vDDDTypes object at 0x7f6e6cc75b90>
LOCATION 
SEQUENCE 2
STATUS CONFIRMED
SUMMARY this WEEK in TECH
TRANSP OPAQUE
--------------------
"""
#!/usr/bin/env node
// Copyright 2026 The Kubernetes Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Writes calendar@kubernetes.io events as a FullCalendar JSON feed, built from
// the public iCalendar feed, so the site needs no Google API key.
//
// Usage: node hack/gen-calendar.js <output.json>

const fs = require('fs');
const ICAL = require('ical.js');

const CALENDAR_ID = 'calendar@kubernetes.io';
// The JSON file has events from MONTHS_BACK months ago to MONTHS_AHEAD months ahead.
const MONTHS_BACK = 3;
const MONTHS_AHEAD = 13;

// Google event IDs use base32hex: 0-9 then a-v.
const BASE32HEX = '0123456789abcdefghijklmnopqrstuv';

function base32hex(text) {
  const bits = [...Buffer.from(text)].map((b) => b.toString(2).padStart(8, '0')).join('');
  return bits.match(/.{1,5}/g).map((c) => BASE32HEX[parseInt(c.padEnd(5, '0'), 2)]).join('');
}

// Same link the Google Calendar plugin used: eid = base64("<event id> <calendar id>").
// The event ID is the UID without "@google.com", or "_" + base32hex(UID) for
// imported events (for example Zoom invites). Occurrences add "_<UTC start>",
// and split series drop the "_R<start>" UID suffix.
function googleEventUrl(uid, recurrenceId) {
  let id = uid.endsWith('@google.com') ? uid.slice(0, -'@google.com'.length) : '_' + base32hex(uid);
  if (recurrenceId) {
    id = id.replace(/_R\d{8}T\d{6}$/, '') + '_' + recurrenceId.convertToZone(ICAL.Timezone.utcTimezone).toICALString();
  }
  return 'https://www.google.com/calendar/event?eid=' + Buffer.from(`${id} ${CALENDAR_ID}`).toString('base64').replace(/=+$/, '');
}

const time = (t) => (t.isDate ? t.toString() : t.toJSDate().toISOString());

function expand(icsText, from, to) {
  const calendar = new ICAL.Component(ICAL.parse(icsText));
  calendar.getAllSubcomponents('vtimezone').forEach((tz) => ICAL.TimezoneService.register(tz));
  const start = ICAL.Time.fromJSDate(from, true);
  const end = ICAL.Time.fromJSDate(to, true);

  const vevents = calendar.getAllSubcomponents('vevent');
  const overrides = {};
  for (const v of vevents.filter((v) => v.hasProperty('recurrence-id'))) {
    (overrides[v.getFirstPropertyValue('uid')] ||= []).push(v);
  }

  const events = [];
  const masters = new Set();
  for (const v of vevents.filter((v) => !v.hasProperty('recurrence-id'))) {
    const uid = v.getFirstPropertyValue('uid');
    masters.add(uid);
    // Pass exceptions explicitly. Without this option ical.js attaches every
    // override in the whole calendar to each event, whatever its UID.
    const event = new ICAL.Event(v, { exceptions: overrides[uid] || [] });
    const it = event.iterator();
    for (let next = it.next(); next && next.compare(end) < 0; next = it.next()) {
      const occ = event.getOccurrenceDetails(next);
      if (occ.endDate.compare(start) <= 0 || occ.item.component.getFirstPropertyValue('status') === 'CANCELLED') continue;
      events.push({
        title: occ.item.summary || '',
        start: time(occ.startDate),
        end: time(occ.endDate),
        allDay: occ.startDate.isDate,
        url: googleEventUrl(uid, event.isRecurring() ? occ.recurrenceId : null),
      });
    }
  }

  // An override whose series is not in the feed is shown as a single event.
  for (const v of vevents.filter((v) => v.hasProperty('recurrence-id') && !masters.has(v.getFirstPropertyValue('uid')))) {
    const event = new ICAL.Event(v, { exceptions: [] });
    if (event.endDate.compare(start) <= 0 || event.startDate.compare(end) >= 0 || v.getFirstPropertyValue('status') === 'CANCELLED') continue;
    events.push({
      title: event.summary || '',
      start: time(event.startDate),
      end: time(event.endDate),
      allDay: event.startDate.isDate,
      url: googleEventUrl(event.uid, event.recurrenceId),
    });
  }
  return events;
}

async function main() {
  const output = process.argv[2];
  let ics;
  try {
    const res = await fetch(`https://calendar.google.com/calendar/ical/${encodeURIComponent(CALENDAR_ID)}/public/basic.ics`,
      { signal: AbortSignal.timeout(120000) });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    ics = await res.text();
  } catch (err) {
    // Production keeps its last deploy if the build fails. Deploy Previews
    // and local builds should not fail because Google is down.
    if (process.env.CONTEXT === 'production') throw err;
    console.warn(`gen-calendar: ${err.message}; writing an empty calendar`);
    fs.writeFileSync(output, '[]');
    return;
  }
  const now = new Date();
  const events = expand(ics,
    new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - MONTHS_BACK, 1)),
    new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + MONTHS_AHEAD, 1)));
  if (!events.length) throw new Error('calendar feed has no events; refusing to publish an empty calendar');
  fs.writeFileSync(output, JSON.stringify(events));
  console.log(`gen-calendar: wrote ${events.length} events to ${output}`);
}

if (require.main === module) {
  main().catch((err) => {
    console.error(`gen-calendar: ${err.message}`);
    process.exit(1);
  });
}

module.exports = { expand, googleEventUrl };

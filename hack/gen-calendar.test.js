// Run: node --test hack/gen-calendar.test.js
const assert = require('node:assert');
const test = require('node:test');
const ICAL = require('ical.js');
const { expand, googleEventUrl } = require('./gen-calendar');

const eid = (url) => Buffer.from(url.split('eid=')[1], 'base64').toString();
const utc = (s) => ICAL.Time.fromJSDate(new Date(s + 'Z'), true);

test('event links match Google Calendar event IDs', () => {
  // Expected values come from htmlLink in the Google Calendar API.
  assert.strictEqual(eid(googleEventUrl('gspd85qc93v5fidpdudg71pbo8@google.com', utc('2026-11-12T17:30:00'))),
    'gspd85qc93v5fidpdudg71pbo8_20261112T173000Z calendar@kubernetes.io');
  assert.strictEqual(eid(googleEventUrl('l5hko5i07c35aqdgit2955594u_R20260731T150000@google.com', utc('2026-11-20T16:00:00'))),
    'l5hko5i07c35aqdgit2955594u_20261120T160000Z calendar@kubernetes.io');
  assert.strictEqual(eid(googleEventUrl('EVENTbnCgyJrXQ36gizcLuTS-Mg@zoom.us', utc('2026-12-08T15:00:00'))),
    '_8lb4ajikc9n46prp99p5gk9j6pjmiuj39hql8kpd9ljk0ujfdtmistbj_20261208T150000Z calendar@kubernetes.io');
});

test('overrides only apply to their own series', () => {
  // A and B share a start time, so a mixed-up override would land on A.
  const ics = [
    'BEGIN:VCALENDAR',
    'BEGIN:VEVENT', 'UID:a@google.com', 'SUMMARY:A', 'DTSTART:20261102T100000Z', 'DTEND:20261102T110000Z', 'RRULE:FREQ=WEEKLY', 'END:VEVENT',
    'BEGIN:VEVENT', 'UID:b@google.com', 'SUMMARY:B', 'DTSTART:20261102T100000Z', 'DTEND:20261102T110000Z', 'RRULE:FREQ=WEEKLY', 'END:VEVENT',
    'BEGIN:VEVENT', 'UID:b@google.com', 'SUMMARY:B moved', 'RECURRENCE-ID:20261109T100000Z', 'DTSTART:20261109T150000Z', 'DTEND:20261109T160000Z', 'END:VEVENT',
    'BEGIN:VEVENT', 'UID:b@google.com', 'SUMMARY:B', 'STATUS:CANCELLED', 'RECURRENCE-ID:20261116T100000Z', 'DTSTART:20261116T100000Z', 'DTEND:20261116T110000Z', 'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');
  const got = expand(ics, new Date('2026-11-01T00:00:00Z'), new Date('2026-11-20T00:00:00Z'))
    .map((e) => `${e.title} ${e.start}`).sort();
  assert.deepStrictEqual(got, [
    'A 2026-11-02T10:00:00.000Z',
    'A 2026-11-09T10:00:00.000Z',
    'A 2026-11-16T10:00:00.000Z',
    'B 2026-11-02T10:00:00.000Z',
    'B moved 2026-11-09T15:00:00.000Z',
  ]);
});

test('overrides without their series still show', () => {
  const ics = [
    'BEGIN:VCALENDAR',
    'BEGIN:VEVENT', 'UID:c@google.com', 'SUMMARY:C moved', 'RECURRENCE-ID:20261103T100000Z', 'DTSTART:20261103T120000Z', 'DTEND:20261103T130000Z', 'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');
  const got = expand(ics, new Date('2026-11-01T00:00:00Z'), new Date('2026-11-20T00:00:00Z'));
  assert.deepStrictEqual(got.map((e) => `${e.title} ${e.start}`), ['C moved 2026-11-03T12:00:00.000Z']);
  assert.strictEqual(eid(got[0].url), 'c_20261103T100000Z calendar@kubernetes.io');
});

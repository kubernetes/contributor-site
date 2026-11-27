function openEvent(event) {
  window.open(event.event.url, '_blank', 'width=700,height=700');
  event.jsEvent.preventDefault();
  return false;
};

function renderCalendar(eventsUrl) {
  document.addEventListener('DOMContentLoaded', function() {
    var calendarEl = document.getElementById('calendar');

    if (!calendarEl) {
      console.error('Calendar element not found. Cannot render calendar.');
      return;
    }

    // Fetch the file once. A URL in `events` makes FullCalendar download the
    // file again, with new start and end parameters, for every date range.
    var data = fetch(eventsUrl).then(function(r) {
      if (!r.ok) throw new Error('HTTP ' + r.status);
      return r.json();
    });

    var calendar = new FullCalendar.Calendar(calendarEl, {
      events: function(info, success, failure) {
        data.then(success, failure);
      },
      eventSourceFailure: function(errorObj) {
        console.error('Failed to fetch calendar events:', errorObj);
        calendarEl.innerHTML = '<div class="alert alert-warning">Community Calendar is temporarily unavailable.</div>';
      },
      themeSystem: 'bootstrap',
      initialView: 'listView',
      timezone: 'local',
      nowIndicator: true,
      eventClick: openEvent,
      headerToolbar: getHeaderToolbar(),
      views: {
        listView: {
          type: 'list',
          duration: { weeks: 1 },
          buttonText: 'list',
          listDayFormat: {
            month: 'long',
            year: 'numeric',
            day: 'numeric',
            weekday: 'long'
          }
        },
        dayView: {
          type: 'timeGrid',
          duration: { days: 1 },
          buttonText: 'day',
          allDaySlot: false
        },
        weekView: {
          type: 'timeGrid',
          duration: { weeks: 1 },
          buttonText: 'week',
          aspectRation: 10,
          allDaySlot: false
        },
        monthView: {
          type: 'dayGrid',
          duration: { months: 1 },
          buttonText: 'month',
          dayMaxEvents: 5,
          allDaySlot: false
        },
      }
    });
    calendar.render();
  });
};

// Detect if device is mobile (screen width < 768px)
function isMobileDevice() {
  return window.innerWidth < 768;
}

// Get header toolbar configuration based on device type
function getHeaderToolbar() {
  if (isMobileDevice()) {
    return {
      left: 'listView,dayView',
      center: 'title',
      right: 'prev,today,next'
    };
  } else {
    return {
      left: 'listView,monthView,weekView,dayView',
      center: 'title',
      right: 'prev,today,next'
    };
  }
}
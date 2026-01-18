function openEvent(event) {
    window.open(event.event.url, '_blank', 'width=700,height=700');
    event.jsEvent.preventDefault();
    return false;
  };

function renderCalendar(apiKey) {
  document.addEventListener('DOMContentLoaded', function() {
    var calendarEl = document.getElementById('calendar');
    
    if (!calendarEl) {
      console.error('Calendar element not found. Cannot render calendar.');
      return;
    }
    
    if (!apiKey || apiKey === 'PLACEHOLDER_VALUE') {
      console.warn('Google Calendar API key is missing. Calendar will not render.');
      calendarEl.innerHTML = '<div>Community Calendar is not available in this environment (missing API Key).</div>';
      return;
    }

    var calendar = new FullCalendar.Calendar(calendarEl, {
      googleCalendarApiKey: apiKey,
      events: {
        googleCalendarId: 'calendar@kubernetes.io'
      },
      themeSystem: 'bootstrap',
      aspectRatio: 2.3,
      initialView: 'listView',
      timezone: 'local',
      nowIndicator: true,
      eventClick: openEvent,
      headerToolbar: {
        left: 'listView,dayView,weekView,monthView',
        center: 'title',
        right: 'prev,today,next'
      },
      views: {
        listView: {
          type: 'list',
          duration: { weeks: 1},
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
          duration: { days: 1},
          buttonText: 'day'
        },
        weekView: {
          type: 'timeGrid',
          duration: { weeks: 1},
          buttonText: 'week',
          aspectRation: 10
        },
        monthView: {
          type: 'dayGrid',
          duration: { months: 1},
          buttonText: 'month',
          dayMaxEvents: 5
        }
      }
    });
    calendar.render();
  });
};

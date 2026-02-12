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
    
    var isProduction = document.documentElement.getAttribute('data-isproduction') === 'true';
    
    if (!apiKey) {
      if (isProduction) {
        console.error('Google Calendar API key is missing in production. Calendar will not render.');
      } else {
        console.warn('Google Calendar API key is missing. Calendar will not render.');
      }
      calendarEl.innerHTML = '<div>Community Calendar is not available in this environment (missing API Key).</div>';
      return;
    }

    var calendar = new FullCalendar.Calendar(calendarEl, {
      googleCalendarApiKey: apiKey,
      events: {
        googleCalendarId: 'calendar@kubernetes.io'
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
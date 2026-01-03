function openEvent(event) {
  window.open(event.event.url, '_blank', 'width=700,height=700');
  event.jsEvent.preventDefault();
  return false;
};

function renderCalendar() {
  document.addEventListener('DOMContentLoaded', function () {
    var calendarEl = document.getElementById('calendar');
    
    var calendar = new FullCalendar.Calendar(calendarEl, {
      googleCalendarApiKey: 'AIzaSyDn_UhFPLDgxouI5nc8hOULFY25EjwGR44',
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
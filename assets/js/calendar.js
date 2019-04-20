function openEvent(event) {
  window.open(event.url, 'gcalevent', 'width=600,height=600');
  return false;
}

function renderCalendar() {
  var calendarEl = document.getElementById('calendar');

  var calendar = new FullCalendar.Calendar(calendarEl, {
    plugins: [ 'list', 'googleCalendar', 'moment' ],
    googleCalendarApiKey: 'AIzaSyDlAwor0K8xljdp_r3V-9nFKnyoBQzm3Ro',
    events: {
      googleCalendarId: 'cgnt364vd8s86hr2phapfjc6uk@group.calendar.google.com'
    },
    eventClick: openEvent,
    defaultView: 'listWeek',
    timezone: 'local',
    displayEventTime: true,
    eventLimit: true,
    navLinks: true,
    header: {
      left: 'prev,today,next',
      center: 'title',
      right: 'agendaDay,agendaWeek,month'
    },
    views: {
      month: {
        eventLimit: 6
      }
    }
  });

  calendar.render();
}

$(function() {
  renderCalendar();
});

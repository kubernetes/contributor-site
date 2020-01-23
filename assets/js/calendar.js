function openEvent(event) {
  window.open(event.url, 'gcalevent', 'width=600,height=600');
  return false;
}

function renderCalendar() {
  var calendarEl = document.getElementById('calendar');

  var calendar = new FullCalendar.Calendar(calendarEl, {
    plugins: [ 'dayGrid', 'googleCalendar', 'moment' ],
    defaultView: 'dayGridWeek',
    googleCalendarApiKey: 'AIzaSyDlAwor0K8xljdp_r3V-9nFKnyoBQzm3Ro',
    events: {
    	googleCalenderId: 'cgnt364vd8s86hr2phapfjc6uk@group.calendar.google.com',
    },
    header: {
      left: 'prev,next today',
      center: 'title,',
      right: 'dayGridDay,dayGridWeek,dayGridMonth'
    },
    eventClick: openEvent,
    timezone: 'local',
    displayEventTime: true,
    eventLimit: true,
    navLinks: true,
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

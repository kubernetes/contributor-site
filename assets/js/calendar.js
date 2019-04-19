function renderCalendar() {
  var calendarEl = document.getElementById('calendar');

  var calendar = new FullCalendar.Calendar(calendarEl, {
    plugins: [ 'dayGrid', 'googleCalendar', 'moment' ],
    googleCalendarApiKey: 'AIzaSyDn_UhFPLDgxouI5nc8hOULFY25EjwGR44',
    events: {
      googleCalendarId: 'cgnt364vd8s86hr2phapfjc6uk@group.calendar.google.com'
    },
    eventClick: function(event) {
      window.open(event.url, 'gcalevent', 'width=600,height=600');
      return false;
    },
    defaultView: 'dayGridWeek',
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

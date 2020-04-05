function openEvent(event) {
  window.open(event.event.url, '_blank', 'width=700,height=700');
  event.jsEvent.preventDefault();
  return false;
}

function renderCalendar() {
  var calendarEl = document.getElementById('calendar');

  var calendar = new FullCalendar.Calendar(calendarEl, {
    plugins: [ 'dayGrid', 'googleCalendar', 'moment' ],
    defaultView: 'dayGridWeek',
    header: {
      left: 'prev,next today',
      center: 'title',
      right: 'dayGridDay,dayGridWeek,dayGridMonth'
    },
    googleCalendarApiKey: 'AIzaSyDlAwor0K8xljdp_r3V-9nFKnyoBQzm3Ro',
    events: 'cgnt364vd8s86hr2phapfjc6uk@group.calendar.google.com',
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
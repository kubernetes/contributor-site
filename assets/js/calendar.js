function openEvent(event) {
  window.open(event.url, 'gcalevent', 'width=600,height=600');
  return false;
}

function renderCalendar() {
  var calendarEl = document.getElementById('calendar');

  var calendar = new FullCalendar.Calendar(calendarEl, {
    plugins: [ 'dayGrid', 'googleCalendar', 'moment' ],
    defaultView: 'dayGridMonth',
    googleCalendarApiKey: 'AIzaSyCePJ8tLdqZTHQ71_17eSCREAh4YXWRVDI',
    events: 'vishakhanihore.10@gmail.com',
    header: {
      left: 'prev,next today',
      center: 'title',
      right: 'dayGridMonth,listYear'
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

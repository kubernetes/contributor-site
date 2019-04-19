function renderCalendar() {
  var calendarEl = document.getElementById('calendar');

  var calendar = new FullCalendar.Calendar(calendarEl, {
    plugins: [ 'dayGrid', 'googleCalendar' ],
    googleCalendarApiKey: 'AIzaSyDn_UhFPLDgxouI5nc8hOULFY25EjwGR44',
    events: {
      googleCalendarId: 'cgnt364vd8s86hr2phapfjc6uk@group.calendar.google.com'
    }
  });

  calendar.render();
}

$(function() {
  renderCalendar();
});

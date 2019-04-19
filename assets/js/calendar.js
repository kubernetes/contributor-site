function renderCalendar() {
  var calendarEl = document.getElementById('calendar');

  var calendar = new FullCalendar.Calendar(calendarEl, {
    timeZone: 'local',
    header: { center: 'dayGridMonth,timeGridWeek' },
    plugins: [ 'dayGrid' ]
  });

  calendar.render();
}

$(function() {
  renderCalendar();
});

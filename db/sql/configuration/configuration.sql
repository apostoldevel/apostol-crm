SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT GetErrorMessage();

SELECT SetDefaultArea(GetArea('default'));
SELECT SetArea(GetArea('default'));

SELECT CreateClassTree();
SELECT CreateObjectType();
SELECT KernelInit();

SELECT FillCalendar(CreateCalendar(null, GetType('workday.calendar'), 'default.calendar', 'Календарь рабочих дней', 5, ARRAY[6,7], ARRAY[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]], '9 hour', '9 hour', '13 hour', '1 hour', 'Календарь рабочих дней.'), '2020/01/01', '2020/12/31');

SELECT SignOut();
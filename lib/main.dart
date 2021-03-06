import 'dart:async';
import 'dart:convert';
import 'package:clouding_calendar/about_page.dart';
import 'package:clouding_calendar/const/gradient_const.dart';
import 'package:clouding_calendar/const/styles.dart';
import 'package:clouding_calendar/reminder.dart';
import 'package:clouding_calendar/signin.dart';
import 'package:clouding_calendar/common/appInfo.dart';
import 'package:clouding_calendar/custom_router.dart';
import 'package:clouding_calendar/event.dart';
import 'package:clouding_calendar/feedback.dart';
import 'package:clouding_calendar/local_notification_helper.dart';
import 'package:clouding_calendar/settings.dart';
import 'package:clouding_calendar/timeline.dart';
import 'package:clouding_calendar/widget/introView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:clouding_calendar/template.dart';
import 'common/Sphelper.dart';
import 'eventDetails.dart';
import 'routes.dart' as rt;
import 'package:http/http.dart' as http;
import 'userServices.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'reminderDetails.dart';
import 'package:clouding_calendar/model/holidays.dart' as holidays;

void main() {
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Color _themeColor;

    // Default theme
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppInfoProvider())
      ],
      child: Consumer<AppInfoProvider>(
        builder: (context, appInfo, _) {
          String colorKey = appInfo.themeColor;
          if (rt.Global.themeColorMap[colorKey] != null) {
            _themeColor = rt.Global.themeColorMap[colorKey];
          }

          return MaterialApp(
            navigatorKey: navigatorKey,
            theme: ThemeData(
              primarySwatch: _themeColor,
              primaryColor: _themeColor,
              accentColor: _themeColor,
              indicatorColor: Colors.white
            ),
            // Validate user login state
            home: FutureBuilder<bool>(
              future: getUserLoginState(),
              builder:(BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.hasData){
                  if (snapshot.data) {
                    return MyHomePage();
                  } else {
                    return IntroViewsFlutter(
                      pages,
                      showNextButton: true,
                      showBackButton: true,
                      onTapDoneButton: () {
                        Navigator.push(
                          context, MaterialPageRoute(
                            builder: (context) => SigninPage(),
                          )
                        );
                      },
                      pageButtonTextStyles: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0
                      ),
                    );
                  }
                }
                else{
                  return IntroViewsFlutter(
                    pages,
                    showNextButton: true,
                    showBackButton: true,
                    onTapDoneButton: () {
                      Navigator.popAndPushNamed(
                        context, 'signinRoute'
                      );
                    },
                    pageButtonTextStyles: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0
                    ),
                  );
                }
              }
            ),
            routes: rt.routes,
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key key, 
    this.title,
    }) : super(key: key);


  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  //Map<DateTime, List> _events;
  List _selectedEvents;
  AnimationController _animationController;
  CalendarController _calendarController;
  FlutterLocalNotificationsPlugin notifications = new FlutterLocalNotificationsPlugin();

  String _reminderId, _remindText, _reminderEmail;
  DateTime _remindTime;
  int _repetition;


  @override
  void initState() {
    super.initState();
    final _selectedDay = DateTime.now();
    _initAsync();

    // 2 timers to monitor notifications
    startTimer();
    startEventTimer();
    /* rt.Global.events = {
      _selectedDay.subtract(Duration(days: 30)): ['Event A0', 'Event B0', 'Event C0'],
    }; */

    _selectedEvents = rt.Global.events[_selectedDay] ?? [];

    _calendarController = CalendarController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animationController.forward();

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    notifications.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  void _initAsync() async {
    await SpHelper.getInstance();
    String colorKey = SpHelper.getString(rt.Global.key_theme_color, defValue: 'purple');
    // Set default them
    Provider.of<AppInfoProvider>(context, listen: false).setTheme(colorKey);
  }

  // The app navigate to the details when the notification is selected
  Future onSelectNotification(String payload) async {
    var payloadList = payload.split(' ');
    print(payload);
    if (payloadList[0] == '1') {
      getReminderDetail(payloadList[1]);
    } else {
      getEventDetail(payloadList[1]);
    }
  }

  Future onDidReceiveLocalNotification(
    int id, String title, String body, String payload) async {
  // display a dialog with the notification details, tap ok to go to another page
  showDialog(
    context: context,
    builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Text(title),
        content: new Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: new Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                new MaterialPageRoute(
                  builder: (context) => new MyHomePage(),
                ),
              );
            },
          )
        ],
      ),
    );
  }


  @override
  void dispose() {
    _animationController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime day, List events) {
    //print('CALLBACK: _onDaySelected');
    setState(() {
      _selectedEvents = events;
    });
  }

  void _onVisibleDaysChanged(DateTime first, DateTime last, CalendarFormat format) {
    print('CALLBACK: _onVisibleDaysChanged');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //Right corner 'setting'
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {Share.share('Zalendar\n http://github.com/zwx0641');},
          ),
        ],
        title: Text('Zalendar', style: TextStyle(
                fontSize: 22.0,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.normal),),
      ),
      // Drawer on the left hand
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(gradient: SIGNUP_BACKGROUND),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              FutureBuilder(
                future: getUserVO(),
                builder: (context, snapshot) {
                  //return header('email', '');
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data != null) {
                      return header(snapshot.data['data']['email'], snapshot.data['data']['face_image'] == null 
                                            ? '' : snapshot.data['data']['face_image']);
                    } else {
                      return header('email', '');
                    }
                  } else {
                    return header('email', '');
                  }
                },
              ),
              ListTile(
                title: Text('Month', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.today),),
                onTap: () {
                  setState(() {
                    _calendarController.setCalendarFormat(CalendarFormat.month);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('2weeks', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.view_array),),
                onTap: () {
                  setState(() {
                    _calendarController.setCalendarFormat(CalendarFormat.twoWeeks); 
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Week', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.view_day),),
                onTap: () {
                  setState(() {
                    _calendarController.setCalendarFormat(CalendarFormat.week); 
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Agenda', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.view_agenda),),
                onTap: () {
                  Navigator.push(context, new CustomRoute(TimelinePage(title: 'Agenda',)));
                },
              ),
              ListTile(
                title: Text('Settings', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.settings),),
                onTap: () {
                  Navigator.push(context, new CustomRoute(SettingPage()));
                },
              ),
              ListTile(
                title: Text('Help', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.help),),
                onTap: () {
                  Navigator.push(context, new CustomRoute(FeedbackPage(title: 'Support')));
                },
              ),
              ListTile(
                title: Text('Feedbacks', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.feedback),),
                onTap: () {
                  Navigator.push(context, new CustomRoute(FeedbackPage(title: 'Feedbacks')));
                },
              ),
              ListTile(
                title: Text('About', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.info),),
                onTap: () {
                  Navigator.push(context, new CustomRoute(MyAboutPage()));
                },
              ),
              ListTile(
                title: Text('Logout', style: hintAndValueStyle,),
                leading: new CircleAvatar(child: new Icon(Icons.power_settings_new),),
                onTap: () {
                  Navigator.popAndPushNamed(context, 'signinRoute');
                  logout();
                },
              )
            ],
          ),
        ),
      ),
      // Load reminders when in main page
      body: Container(
        decoration: BoxDecoration(gradient: SIGNUP_BACKGROUND),
        child: FutureBuilder(
          future: getReminderEvent(),
          builder: (context, snapshot) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                // Switch out 2 lines below to play with TableCalendar's settings
                //-----------------------
                rt.Global.calendarType == 1 ? _buildTableCalendarWithBuilders(snapshot.data) 
                                            : _buildTableCalendar(snapshot.data),
                
                const SizedBox(height: 8.0),
                const SizedBox(height: 8.0),
                Expanded(child: _buildEventList()),
                
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey,
        onPressed: _addActivities,
        child: new Icon(Icons.add),
      ),
    );
  }

  // Tap + to add event/reminder
  void _addActivities() {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Stack(
            children: <Widget>[
              Container(
                height: 25,
                width: double.infinity,
                color: Colors.black54,
              ),
              Container(
                height: 112,
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    //添加需要完成的事件
                    new ListTile(
                      leading: new Icon(Icons.event, color: Colors.black),
                      title: new Text('Event', style: hintAndValueStyle),
                      onTap: () {
                        Navigator.of(context).push(new CustomRoute(new EventPage()));
                      },
                    ),
                    //添加提醒
                    new ListTile(
                      leading: new Icon(Icons.alarm_add, color: Colors.black),
                      title: new Text('Reminder', style: hintAndValueStyle),
                      onTap: () {
                        Navigator.of(context).push(new CustomRoute(new ReminderPage(
                          id: null, remindText: null,
                          remindTime: null, email: null,
                          repetition: 1,
                        )));
                      },
                    )
                  ],
                ),
                decoration: BoxDecoration(
                  gradient: SIGNUP_BACKGROUND,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25)
                  )
                ),
              ),
              
            ],
          );
        }
      );
  }

  // Simple TableCalendar configuration (using Styles)
  Widget _buildTableCalendar(Map map) {
    return TableCalendar(
      calendarController: _calendarController,
      events: map,
      holidays: holidays.Holidays.holidays,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        selectedColor: Colors.purple[200],
        todayColor: Colors.purple[100],
        markersColor: Colors.brown[700],
        outsideDaysVisible: false,
      ),
      headerStyle: HeaderStyle(
        formatButtonTextStyle: TextStyle().copyWith(color: Colors.white, fontSize: 15.0),
        formatButtonDecoration: BoxDecoration(
          color: Colors.purple[200],
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      onDaySelected: _onDaySelected,
      onVisibleDaysChanged: _onVisibleDaysChanged,
    );
  }

  // More advanced TableCalendar configuration (using Builders & Styles)
  Widget _buildTableCalendarWithBuilders(Map map) {
    return TableCalendar(
      locale: 'en_US',
      calendarController: _calendarController,
      events: map,
      holidays: holidays.Holidays.holidays,
      initialCalendarFormat: CalendarFormat.month,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      availableGestures: AvailableGestures.all,
      availableCalendarFormats: const {
        CalendarFormat.month: '',
        CalendarFormat.week: '',
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendStyle: TextStyle().copyWith(color: Colors.purple[800]),
        holidayStyle: TextStyle().copyWith(color: Colors.purple[800]),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekendStyle: TextStyle().copyWith(color: Colors.purple[600]),
      ),
      headerStyle: HeaderStyle(
        centerHeaderTitle: true,
        formatButtonVisible: false,
      ),
      builders: CalendarBuilders(
        selectedDayBuilder: (context, date, _) {
          return FadeTransition(
            opacity: Tween(begin: 0.0, end: 1.0).animate(_animationController),
            child: Container(
              margin: const EdgeInsets.all(4.0),
              padding: const EdgeInsets.only(top: 5.0, left: 6.0),
              color: Colors.purple[300],
              width: 100,
              height: 100,
              child: Text(
                '${date.day}',
                style: TextStyle().copyWith(fontSize: 16.0),
              ),
            ),
          );
        },
        todayDayBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            padding: const EdgeInsets.only(top: 5.0, left: 6.0),
            color: Colors.purple[100],
            width: 100,
            height: 100,
            child: Text(
              '${date.day}',
              style: TextStyle().copyWith(fontSize: 16.0),
            ),
          );
        },
        markersBuilder: (context, date, events, holidays) {
          final children = <Widget>[];

          if (events.isNotEmpty) {
            children.add(
              Positioned(
                right: 1,
                bottom: 1,
                child: _buildEventsMarker(date, events),
              ),
            );
          }

          if (holidays.isNotEmpty) {
            children.add(
              Positioned(
                right: -2,
                top: -2,
                child: _buildHolidaysMarker(),
              ),
            );
          }

          return children;
        },
      ),
      onDaySelected: (date, events) {
        _onDaySelected(date, events);
        _animationController.forward(from: 0.0);
      },
      onVisibleDaysChanged: _onVisibleDaysChanged,
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: _calendarController.isSelected(date)
            ? Colors.brown[500]
            : _calendarController.isToday(date) ? Colors.brown[300] : Colors.blue[400],
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  // Display holidays with an icon
  Widget _buildHolidaysMarker() {
    return Icon(
      Icons.add_box,
      size: 20.0,
      color: Colors.blueGrey[800],
    );
  }

  Widget _buildEventList() {
    return ListView(
      children: _selectedEvents
          .map((event) => Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 0.8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(event.toString(), style: hintAndValueStyle,),
                  onTap: () {
                    //POST to get the reminder's detail
                    getReminderDetail(event.toString());
                    
                  },
                ),
              ))
          .toList(),
    );
  }

  logout() async {
    // Get local cache
    var userId = await getGlobalUserInfo();
    var url = rt.Global.serverUrl + '/logout?userId=' + userId; 
    // Delete redis cache
    var response = await http.post(
      Uri.encodeFull(url),
      headers: {
        "content-type" : "application/json",
        "accept" : "application/json",
      }
    );
    var data = jsonDecode(response.body.toString());
    var status = data['status'];

    
    if (status == 200) {
      Fluttertoast.showToast(
        msg: 'Logout successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER
      );
      // Delete local cache
      //deleteGloabalUserInfo();
      // Set user state as logout
      setUserLoginState(false);
      // Navigator.popAndPushNamed(context, 'signinRoute');
    }
  }

  startTimer() async {
    // Set a timer 
    Timer timer = new Timer.periodic(new Duration(seconds: 10), (timer) async {
      // Find reminders according to email
      String email = await getUserEmail();
      var url = rt.Global.serverUrl + '/reminder/query?email=' + email;
      var response =  await http.post(
        Uri.encodeFull(url),
        headers: {
          "content-type" : "application/json",
          "accept" : "application/json",
        }
      );
      var data = jsonDecode(response.body.toString());
      List reminderList = data['data'];
      
      // Send notifications if time arrived
      if (reminderList?.isNotEmpty) {
        int id = -1;
        for (var reminder in reminderList) {
          DateTime remindTime = DateTime.fromMillisecondsSinceEpoch(reminder['remindTime']);
          if (DateTime.now().compareTo(remindTime) == 1) {
            id += 1;
            showOngoingNotification(
              notifications, 
              title: "Don't forget this!", 
              body: reminder['remindText'],
              payload: '1 ' + reminder['remindText'],
              id: id,
            );
            if (reminder['repetition'] == 0) {
              url = rt.Global.serverUrl + '/reminder/drop?id=' + reminder['id'];
              response = await http.post(
                Uri.encodeFull(url),
                headers: {
                  "content-type" : "application/json",
                  "accept" : "application/json",
                }
              );
            } else {
              // Update the next remind time
              url = rt.Global.serverUrl + '/reminder/update?id=' + reminder['id'];
              response = await http.post(
                Uri.encodeFull(url),
                headers: {
                  "content-type" : "application/json",
                  "accept" : "application/json",
                }
              );
            }
          }
          getReminderEvent();
        }
      }
    });
  }

  startEventTimer() async {
    // Start a monitor
    Timer timer = new Timer.periodic(new Duration(seconds: 10), (timer) async {
      // Find reminders according to the username
      String email = await getUserEmail();
      var url = rt.Global.serverUrl + '/event/query?email=' + email;
      var response =  await http.post(
        Uri.encodeFull(url),
        headers: {
          "content-type" : "application/json",
          "accept" : "application/json",
        }
      );
      var data = jsonDecode(response.body.toString());
      List eventList = data['data'];
      // Do different things
      
      if (eventList?.isNotEmpty) {
        int id = -1;
        for (var event in eventList) {
          DateTime fromTime = DateTime.fromMillisecondsSinceEpoch(event['fromTime']);
          
          if (DateTime.now().compareTo(fromTime) == 1) {
            id += 1;
            showOngoingNotification(
              notifications, 
              title: "On your schedule: ", 
              body: event['eventName'],
              payload: '2 ' + event['id'],
              id: id,
            );
            if (event['repetition'] == 0) {
              url = rt.Global.serverUrl + '/event/drop?id=' + event['id'];
              response = await http.post(
                Uri.encodeFull(url),
                headers: {
                  "content-type" : "application/json",
                  "accept" : "application/json",
                }
              );
            } else {
              url = rt.Global.serverUrl + '/event/update?id=' + event['id'];
              response = await http.post(
                Uri.encodeFull(url),
                headers: {
                  "content-type" : "application/json",
                  "accept" : "application/json",
                }
              );
            }
          }
        }
      }
    });
  }

  getReminderDetail(String remindText) async {
    // Get the details of a reminder
    String email = await getUserEmail();
    var url = rt.Global.serverUrl + '/reminder/detail?email=' + email + '&remindText=' + remindText;
    var response =  await http.post(
      Uri.encodeFull(url),
      headers: {
        "content-type" : "application/json",
        "accept" : "application/json",
      }
    );
    var data = jsonDecode(response.body.toString());
    List reminderList = data['data'];

    if (reminderList?.isNotEmpty) {
      for (var reminder in reminderList) {
        _reminderId = reminder['id'];
        _reminderEmail = reminder['email'];
        _remindText = reminder['remindText'];
        _remindTime = DateTime.fromMillisecondsSinceEpoch(reminder['remindTime']);;
        _repetition = reminder['repetition'];
      }
    }
    
    // Show details of a reminder
    Navigator.of(context).push(
      PageRouteBuilder<Null>(
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget child) {
                return Opacity(
                  opacity: animation.value,
                  child: ReminderDetails(_reminderId, _reminderEmail, _remindText, _remindTime, _repetition),
                );
              });
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  getEventDetail(String id) async {
    // Get the details of an event
    var url = rt.Global.serverUrl + '/event/detail?id=' + id;
    var response =  await http.post(
      Uri.encodeFull(url),
      headers: {
        "content-type" : "application/json",
        "accept" : "application/json",
      }
    );
    var data = jsonDecode(response.body.toString());
    List eventList = data['data'];

    String _eventId, _eventEmail, _eventName, _location, _remark;
    DateTime _fromTime, _endTime;
    int _eventType, _repetition;

    if (eventList?.isNotEmpty) {
      for (var event in eventList) {
        _eventId = event['id'];
        _eventEmail = event['email'];
        _eventName = event['eventName'];
        _location = event['location'];
        _remark = event['remark'];
        _fromTime = DateTime.fromMillisecondsSinceEpoch(event['fromTime']);
        _endTime = DateTime.fromMillisecondsSinceEpoch(event['endTime']);
        _eventType = event['eventType'];
        _repetition = event['repetition'];
      }
    }
    
    Navigator.of(context).push(
      PageRouteBuilder<Null>(
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget child) {
                return Opacity(
                  opacity: animation.value,
                  child: EventDetails(
                    _eventId, _eventEmail,
                    _eventName, _location,
                    _remark, _fromTime,
                    _endTime, _eventType, _repetition,
                  ),
                );
              });
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }
}
import 'dart:convert';

import 'package:clouding_calendar/const/color_const.dart';
import 'package:clouding_calendar/const/gradient_const.dart';
import 'package:clouding_calendar/main.dart';
import 'package:clouding_calendar/userServices.dart';
import 'package:clouding_calendar/widget/signup_apbar.dart';
import 'package:clouding_calendar/widgets/errorDialog.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:clouding_calendar/routes.dart' as rt;
import 'package:http/http.dart' as http;

import 'common/app_theme.dart';
import 'const/size_const.dart';

String _eventName, _location, _remark;
DateTime _selectedFromDate;
TimeOfDay _selectedFromTime;
DateTime _selectedEndDate;
TimeOfDay _selectedEndTime;
int _repetition;
int _eventType;

class EventPage extends StatefulWidget {
  final String id;
  final String email;
  final String eventName;
  final String location;
  final String remark;
  final DateTime fromTime;
  final DateTime endTime;
  final int eventType;
  final int repetition;

  const EventPage({Key key, this.id, this.email, this.eventName, this.location, this.remark, this.fromTime, this.endTime, this.eventType, this.repetition}) : super(key: key);  



  @override
  _EventPageState createState() => _EventPageState(
    id, email, eventName, location, remark, fromTime, endTime, eventType, repetition
  );
}

class _EventPageState extends State<EventPage> {
  // Parameters
  final String id;
  final String email;
  final String eventName;
  final String location;
  final String remark;
  final DateTime fromTime;
  final DateTime endTime;
  final int eventType;
  final int repetition;  



  TextEditingController nameController;
  TextEditingController locationController;
 
  // Repetition selected?
  bool _is0Selected = false;
  bool _is1Selected = false;
  bool _is2Selected = false;
  bool _is3Selected = false;
  bool _is4Selected = false;
  // Event type selected?
  bool _isWSelected = false;
  bool _isSSelected = false;
  bool _isRSelected = false;

  GlobalKey<ScaffoldState> _scaffoldKey;

  _EventPageState(
    this.id, 
    this.email, 
    this.eventName, 
    this.location, 
    this.remark, 
    this.fromTime, 
    this.endTime, 
    this.eventType, 
    this.repetition);

  void dispose() {
    super.dispose();
    nameController.dispose();
    locationController.dispose();
  }

  void initState() {
    super.initState();
    nameController = TextEditingController();
    locationController = TextEditingController();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    
    _repetition = -1;
    _eventType = -1;

    Future.delayed(Duration.zero, () {
      _eventName = eventName;
      _location = location;
      _remark = remark;
      
      if (repetition != null) {
        _repetition = repetition;
        _eventType = eventType;
        switch (repetition) {
          case 0:
            _handle0Changed(true);
            break;
          case 1:
            _handle1Changed(true);
            break;
          case 2:
            _handle2Changed(true);
            break;
          case 3:
            _handle3Changed(true);
            break;
          case 4:
            _handle4Changed(true);
            break;
          default:
        }
        switch (eventType) {
          case 1:
            _handleWChanged(true);
            break;
          case 2:
            _handleSChanged(true);
            break;
          case 3:
            _handleRChanged(true);
            break;
          default:
        }
      }

      if (fromTime != null) {
        _selectedFromDate = fromTime;
        _selectedEndDate = endTime;
        _selectedFromTime = TimeOfDay(hour: fromTime.hour, minute: fromTime.minute);
        _selectedEndTime = TimeOfDay(hour: endTime.hour, minute: endTime.minute);
      }
    });
  }

  // 判断哪种重复被选择
  void _handle0Changed(bool value) {
    setState(() {
      if (_is1Selected || _is2Selected || _is3Selected || _is4Selected) {
        _is1Selected = _is2Selected = _is3Selected = _is4Selected = false;
        _is0Selected = true;
        _repetition = 0;
      } else {
        _is0Selected = value;
        if (!value) {_repetition = -1;} else {_repetition = 0;}
      }
    });
  }
  void _handle1Changed(bool value) {
    setState(() {
      if (_is0Selected || _is2Selected || _is3Selected || _is4Selected) {
        _is0Selected = _is2Selected = _is3Selected = _is4Selected = false;
        _is1Selected = true;
        _repetition = 1;
      } else {
        _is1Selected = value;
        if (!value) {_repetition = -1;} else {_repetition = 1;}
      }
    });
  }
  void _handle2Changed(bool value) {
    setState(() {
      if (_is1Selected || _is0Selected || _is3Selected || _is4Selected) {
        _is1Selected = _is0Selected = _is3Selected = _is4Selected = false;
        _is2Selected = true;
        _repetition = 2;
      } else {
        _is2Selected = value;
        if (!value) {_repetition = -1;} else {_repetition = 2;}
      }
    });
  }
  void _handle3Changed(bool value) {
    setState(() {
      if (_is1Selected || _is2Selected || _is0Selected || _is4Selected) {
        _is1Selected = _is2Selected = _is0Selected = _is4Selected = false;
        _is3Selected = true;
        _repetition = 3;
      } else {
        _is3Selected = value;
        if (!value) {_repetition = -1;} else {_repetition = 3;}
      }
    });
  }
  void _handle4Changed(bool value) {
    setState(() {
      if (_is1Selected || _is2Selected || _is3Selected || _is0Selected) {
        _is1Selected = _is2Selected = _is3Selected = _is0Selected = false;
        _is4Selected = true;
        _repetition = 4;
      } else {
        _is4Selected = value;
        if (!value) {_repetition = -1;} else {_repetition = 4;}
      }
    });
  }

  //event type controller
  void _handleWChanged(bool value) {
    setState(() {
      if (_isSSelected || _isRSelected) {
        _isRSelected = _isSSelected = false;
        _isWSelected = true;
        _eventType = 1;
      } else {
        _isWSelected = value;
        if (!value) {_eventType = -1;} else {_eventType = 1;}
      }
    });
  }

  void _handleSChanged(bool value) {
    setState(() {
      if (_isWSelected || _isRSelected) {
        _isRSelected = _isWSelected = false;
        _isSSelected = true;
        _eventType = 2;
      } else {
        _isSSelected = value;
        if (!value) {_eventType = -1;} else {_eventType = 2;}
      }
    });
  }

  void _handleRChanged(bool value) {
    setState(() {
      if (_isSSelected || _isWSelected) {
        _isWSelected = _isSSelected = false;
        _isRSelected = true;
        _eventType = 3;
      } else {
        _isRSelected = value;
        if (!value) {_eventType = -1;} else {_eventType = 3;}
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final _media = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      appBar: SignupApbar(
        title: "CREATE EVENT",
      ),
      body: Stack(
        children: <Widget>[
          Container(
            height: _media.height,
            width: _media.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'images/signup_page_11_bg.png',
                ),
                fit: BoxFit.fill,
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.symmetric(
              horizontal: 25,
            ),
            children: <Widget>[
              PanelTitle(
                title: "Event Name",
                isRequired: true,
              ),
              TextFormField(
                initialValue: _eventName,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                ),
                //controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _eventName = value;
                  });
                },
              ),
              PanelTitle(
                title: "Location",
                isRequired: false,
              ),
              TextFormField(
                initialValue: _location,
//                controller: locationController,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                ),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _location = value;
                  });
                },
              ),
              PanelTitle(
                title: "Remark",
                isRequired: false,
              ),
              _buildComposer(),
              SizedBox(
                height: 15,
              ),

              PanelTitle(
                title: "Repeat Type",
                isRequired: false,
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: StreamBuilder(
                  
                  builder: (context, snapshot) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        RepeatTypeColumn(
                            type: 0,
                            name: "No repeat",
                            iconValue: Icons.timer_off,
                            isSelected: _is0Selected,
                            onChanged: _handle0Changed,
                        ),
                        RepeatTypeColumn(
                            type: 1,
                            name: "Daily",
                            iconValue: Icons.loop,
                            isSelected: _is1Selected,
                            onChanged: _handle1Changed,
                        ),
                        RepeatTypeColumn(
                            type: 2,
                            name: "Weekly",
                            iconValue: Icons.view_array,
                            isSelected: _is2Selected,
                            onChanged: _handle2Changed,
                        ),
                        RepeatTypeColumn(
                            type: 3,
                            name: "Monthly",
                            iconValue: Icons.view_week,
                            isSelected: _is3Selected,
                            onChanged: _handle3Changed,
                        ),
                        RepeatTypeColumn(
                            type: 4,
                            name: "Yearly",
                            iconValue: Icons.timelapse,
                            isSelected: _is4Selected,
                            onChanged: _handle4Changed,
                        ),
                      ],
                    );
                  },
                ),
              ),

              PanelTitle(
                title: "Event Type",
                isRequired: false,
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: StreamBuilder(
                  
                  builder: (context, snapshot) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        RepeatTypeColumn(
                            type: 1,
                            name: "Work",
                            iconValue: Icons.work,
                            isSelected: _isWSelected,
                            onChanged: _handleWChanged,
                        ),
                        RepeatTypeColumn(
                            type: 2,
                            name: "Sport",
                            iconValue: Icons.pool,
                            isSelected: _isSSelected,
                            onChanged: _handleSChanged,
                        ),
                        RepeatTypeColumn(
                            type: 3,
                            name: "Relax",
                            iconValue: Icons.music_note,
                            isSelected: _isRSelected,
                            onChanged: _handleRChanged,
                        ),
                      ],
                    );
                  },
                ),
              ),

              PanelTitle(
                title: "Starting Time",
                isRequired: true,
              ),
              SelectDateTime(type: 1),
              PanelTitle(
                title: "Ending Time",
                isRequired: true,
              ),
              SelectDateTime(type: 2),
              SizedBox(
                height: 35,
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.height * 0.10,
                  right: MediaQuery.of(context).size.height * 0.10,
                ),
                child: Container(
                  width: 200,
                  height: 60,
                  child: InkWell(
                    child: Container(
                      alignment: Alignment.center,
                      height: 45,
                      width: 120,
                      decoration: BoxDecoration(
                        gradient: SIGNUP_CIRCLE_BUTTON_BACKGROUND,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Confirm',
                        style: TextStyle(
                          color: YELLOW,
                          fontWeight: FontWeight.w700,
                          fontSize: TEXT_NORMAL_SIZE,
                          fontFamily: 'Montserrat'
                        ),
                      ),
                    ),
                    onTap: () {
                      if (_eventName == null) {
                        _showErrorDialog('Caution', 'Please enter event name');
                      } else if (_repetition == -1) {
                        _showErrorDialog('Caution', 'Please select whether to repeat');
                      } else if (_eventType == -1) {
                        _showErrorDialog('Caution', 'Please select event type');
                      } else {
                        _saveEvent();
                      }
                    },
                  ),
                ),
              ),
            ],
         
        ),
        ],
      ),
        
      
    );
  }

    Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 32, right: 32),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.grey.withOpacity(0.8),
                offset: const Offset(4, 4),
                blurRadius: 8),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(4.0),
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 160),
            color: AppTheme.white,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0),
              child: TextFormField(
                initialValue: _remark,
                maxLines: null,
                onChanged: (String txt) {
                  _remark = txt;
                },
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: AppTheme.dark_grey,
                ),
                cursorColor: Colors.blue,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your remark...'),
              ),
            ),
          ),
        ),
      ),
    );
  }

    // Save event to database
  _saveEvent() async {
    //Record remind time
    final dft = DateTime(_selectedFromDate.year, _selectedFromDate.month, 
                        _selectedFromDate.day, _selectedFromTime.hour, _selectedFromTime.minute);
    final det = DateTime(_selectedEndDate.year, _selectedEndDate.month, 
                        _selectedEndDate.day, _selectedEndTime.hour, _selectedEndTime.minute);
    final format = new DateFormat('yyyy-MM-dd HH:mm:ss');
    
    String _fromTime = format.format(dft);
    String _endTime = format.format(det);
    //Which user sets the reminder
    String email = await getUserEmail();
    _fromTime = _fromTime.replaceAll(' ', 'T');
    _endTime = _endTime.replaceAll(' ', 'T');
    var url = rt.Global.serverUrl + '/event/save';
    var response = await http.post(
      Uri.encodeFull(url),
      body: json.encode({
          'id' : id,
          'email' : email,
          'eventName' : _eventName,
          'location' : _location,
          'remark' : _remark,
          'fromTime' : _fromTime,
          'endTime' : _endTime,
          'repetition' : _repetition,
          'eventType' : _eventType
        }
      ),
      headers: {
        "content-type" : "application/json",
        "accept" : "application/json",
      }
    );
    var data = jsonDecode(response.body.toString());
    var code = data['status'];
    if (code != 200) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  SizedBox(height: 15),
                  Text('Failed to set a event', style: TextStyle(fontSize: 20),),
                ],
              ),
            ),
            actions: <Widget>[
              new MaterialButton(
                child: new Text('Confirm', style: TextStyle(color: Colors.white),),
                onPressed: () {Navigator.of(context).pop();},
                color: Colors.blueGrey,
              )
            ],
          );
        }
      );
    } else {
      Navigator.pushAndRemoveUntil(context, new MaterialPageRoute(
        builder: (BuildContext buildContext) {
          return MyHomePage();
        }
      ), (route) => route == null);
      Fluttertoast.showToast(
        msg: 'Event saved, you can review them in Agenda',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER
      );
    }
  }

  // A dialog showing errors
  Future<Widget> _showErrorDialog(String title, String msg) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ErrorDialog(title: title, message: msg);
      }
    );
  }
}

class SelectDateTime extends StatefulWidget {
  final int type;
  @override
  _SelectDateTimeState createState() => _SelectDateTimeState(type: type);

  /// type 1: From

  /// type 2: End

  SelectDateTime({Key key, @required this.type}) : super (key: key);
}

class _SelectDateTimeState extends State<SelectDateTime> {
  final int type;

  _SelectDateTimeState({Key key, @required this.type});

  bool _dateClicked = false;
  bool _timeClicked = false;

  Future<DateTime> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate == null ? DateTime.now() : _selectedFromDate, 
      firstDate: DateTime(1970), 
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateClicked = true;
        if (type == 1) {
          _selectedFromDate = picked;
        } else if (type == 2) {
          _selectedEndDate = picked;
        }
      });
    }
    return picked;
  }

  Future<TimeOfDay> _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: _selectedFromTime == null ? TimeOfDay(hour: 0, minute: 00) : _selectedFromTime,
    );
    if (picked != null) {
      setState(() {
        if (type == 1) {
          _selectedFromTime = picked;
        } else if (type == 2) {
          _selectedEndTime = picked;
        }
        _timeClicked = true;
      });
    }
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: Padding(
        padding: EdgeInsets.only(top: 10.0, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            InkWell(
              child: Container(
                alignment: Alignment.center,
                height: 45,
                width: 120,
                decoration: BoxDecoration(
                  gradient: SIGNUP_CIRCLE_BUTTON_BACKGROUND,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  type == 1 ? (_selectedFromDate == null ? 'Pick Date' : 
                  formatDate(_selectedFromDate, [yyyy, '-', mm, '-', 'dd'])) :
                  (_selectedEndDate == null ? 'Pick Date' : 
                  formatDate(_selectedEndDate, [yyyy, '-', mm, '-', 'dd'])),

                  style: TextStyle(
                    color: YELLOW,
                    fontWeight: FontWeight.w700,
                    fontSize: TEXT_NORMAL_SIZE,
                    fontFamily: 'Montserrat'
                  ),
                ),
              ),
              onTap: () {
                _selectDate(context);
              },
            ),
            InkWell(
              child: Container(
                alignment: Alignment.center,
                height: 45,
                width: 120,
                decoration: BoxDecoration(
                  gradient: SIGNUP_CIRCLE_BUTTON_BACKGROUND,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  type == 1 ? (_selectedFromTime == null ? 'Pick Time' : 
                  '${_selectedFromTime.format(context)}' ) :
                  (_selectedEndTime == null ? 'Pick Time' : 
                  '${_selectedEndTime.format(context)}' ),
                  
                  style: TextStyle(
                    color: YELLOW,
                    fontWeight: FontWeight.w700,
                    fontSize: TEXT_NORMAL_SIZE,
                    fontFamily: 'Montserrat'
                  ),
                ),
              ),
              onTap: () {
                _selectTime(context);
              },
            ),
            
          ],
        ),
      ),
    );
  }
}


// Repeat icon and text
class RepeatTypeColumn extends StatelessWidget {
  final String name;
  final IconData iconValue;
  final bool isSelected;
  final int type;
  final ValueChanged<bool> onChanged;

  RepeatTypeColumn(
      {Key key,
      @required this.type,
      @required this.name,
      @required this.iconValue,
      @required this.isSelected,
      @required this.onChanged,
      })
      : super(key: key);

  void _selectedChanged() {
    onChanged(!isSelected);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //呈现改变
      onTap: () {
        _selectedChanged();
      },
      child: Column(
        children: <Widget>[
          Container(
            width: 68,
            
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 14.0),
                child: Icon(
                  iconValue,
                  size: 58,
                  color: YELLOW,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Container(
              width: 63,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? YELLOW : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.black : Colors.yellow,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat'
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PanelTitle extends StatelessWidget {
  final String title;
  final bool isRequired;
  PanelTitle({
    Key key,
    @required this.title,
    @required this.isRequired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 4),
      child: Text.rich(
        TextSpan(children: <TextSpan>[
          TextSpan(
            text: title,
            style: TextStyle(
                fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500, 
                fontFamily: 'Montserrat'),
          ),
          TextSpan(
            text: isRequired ? " *" : "",
            style: TextStyle(fontSize: 14, color: Colors.purple[100]),
          ),
        ]),
      ),
    );
  }
}

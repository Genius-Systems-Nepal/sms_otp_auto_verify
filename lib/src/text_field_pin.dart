import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_otp_auto_verify/src/sms_retrieved.dart';

///your listData length must be equals otp code length.

class TextFieldPin extends StatefulWidget {
  final Function(String, bool)? onOtpCallback;
  final double boxSize;
  final InputBorder? borderStyle;
  final bool filled;
  final int codeLength;
  final filledColor;
  final TextStyle? textStyle;
  final double margin;
  final InputBorder? borderStyeAfterTextChange;
  final bool filledAfterTextChange;

  TextFieldPin(
      {Key? key,
      this.onOtpCallback,
      this.boxSize = 64,
      this.borderStyle,
      this.filled = false,
      this.filledColor = Colors.blue,
      this.codeLength = 5,
      this.textStyle,
      this.margin = 16,
      this.borderStyeAfterTextChange,
      this.filledAfterTextChange = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TextFieldPinState();
  }
}

class _TextFieldPinState extends State<TextFieldPin> {
  _TextFieldPinState();

  List<FocusNode> focusNode = [];
  List<TextEditingController> textController = [];

  List<OtpDefaultData> mListOtpData = [];
  HashMap<int, String> mapResult = HashMap();

  String? _smsCode = "";
  int _nextFocus = 1;
  String _result = "";
  InputBorder? _borderAfterTextChange;

  @override
  void dispose() {
    super.dispose();
    for (int i = 0; i < mListOtpData.length; i++) {
      textController[i].dispose();
    }
    SmsRetrieved.stopListening();
  }

  @override
  void initState() {
    super.initState();

    _setDefaultTextFieldData();

    _startListeningOtpCode();
    if (widget.borderStyeAfterTextChange == null) {
      _borderAfterTextChange = OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey, width: 1));
    } else {
      _borderAfterTextChange = widget.borderStyeAfterTextChange;
    }
  }

  void _setDefaultTextFieldData() {
    for (int i = 0; i < widget.codeLength; i++) {
      mListOtpData.add(OtpDefaultData(null));
      focusNode.add(new FocusNode());
      textController.add(new TextEditingController());
    }
  }

  /// listen sms
  _startListeningOtpCode() async {
    String? smsCode = await SmsRetrieved.startListeningSms();

    _smsCode = getCode(smsCode);

    setState(() {
      _autoFillCode();
    });
  }

  /// auto fill code
  /// clear first list otp data
  /// clear textController
  /// add listOtpData from smsCode value
  _autoFillCode() {
    if (_smsCode != null) {
      mListOtpData.clear();
      textController.clear();
      focusNode.clear();
      List<String> arrCode = _smsCode!.split("");
      for (int i = 0; i < arrCode.length; i++) {
        mListOtpData.add(OtpDefaultData(arrCode[i]));
        focusNode.add(new FocusNode());
        textController
            .add(new TextEditingController(text: mListOtpData[i].code));

        _otpNumberCallback(i, true);
      }
    }
  }

  /// get number from message ex: your code : 45678 blablabla blabla
  getCode(String? sms) {
    if (sms != null) {
      final intRegex = RegExp(r'\d+', multiLine: true);
      final code = intRegex.allMatches(sms).first.group(0);

      return code;
    }
    return null;
  }

  /// get value from textController
  /// check if value already in hashmap ? update value : insert value
  /// convert all values hasmap to string, set as result otp
  _otpNumberCallback(int i, bool isAutoFill) {
    /*if (mapResult.containsKey(i)) {
      mapResult.update(i, (e) => textController[i].text);
    } else {
      mapResult.putIfAbsent(i, () => textController[i].text);
    }
    _result = mapResult.values
        .toString()
        .replaceAll("(", "")
        .replaceAll(")", "")
        .replaceAll(",", "")
        .replaceAll(" ", "");*/
    _result = "";
    for(var controller in textController){
      _result = _result+controller.text.toString();
    }
    _result = _result.trim();
    widget.onOtpCallback!(_result, isAutoFill);
  }

  @override
  Widget build(BuildContext context) {
    InputBorder? _border = widget.borderStyle;

    if (_border == null) {
      _border = OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey,
        ),
      );
    }

    List<Widget> pins = List<Widget>.generate(
        mListOtpData.length, (int index) => _singlePinView(index)).toList();
    return Container(
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: pins),
    );

    return Container(
      height: widget.boxSize,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: ListView.builder(
            itemCount: mListOtpData.length,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, i) {
              return Container(
                width: widget.boxSize,
                height: widget.boxSize,
                margin: EdgeInsets.only(
                    right: i != mListOtpData.length - 1 ? widget.margin : 0),
                child: Center(
                  child: textFieldFill(
                    focusNode: focusNode[i],
                    textEditingController: textController[i],
                    border: _getBorder(i),
                    isFilled: _isFilled(i),
                    onTextChange: (value) {
                      if(value.toString().length > 1 && (i+1 == textController.length  ||textController[i+1].text.length > 0)){
                        textController[i].text = value.toString()[1];
                        if(i+1 == textController.length){
                          _nextFocus = i - 1;
                          FocusScope.of(context)
                              .requestFocus(focusNode[_nextFocus]);
                          Future.delayed(Duration(milliseconds: 2),(){
                            _nextFocus = _nextFocus + 1;
                            FocusScope.of(context)
                                .requestFocus(focusNode[_nextFocus]);
                          });
                        }else{
                          _nextFocus = i + 1;
                          FocusScope.of(context)
                              .requestFocus(focusNode[_nextFocus]);
                        }

                        _otpNumberCallback(i, false);
                      }else{
                        _otpNumberCallback(i, false);

                        if (value.toString().length > 0) {
                          if(value.toString().length > 1){
                            _nextFocus = i + 1;
                            FocusScope.of(context)
                                .requestFocus(focusNode[_nextFocus]);
                            textController[i].text = value.toString()[0];
                            textController[i + 1].text = value.toString()[1];
                            if (i + 2 < focusNode.length) {
                              _nextFocus = i + 2;
                              FocusScope.of(context)
                                  .requestFocus(focusNode[_nextFocus]);
                            }
                          }else {
                            if (_nextFocus != mListOtpData.length) {
                              _nextFocus = i + 1;
                              FocusScope.of(context)
                                  .requestFocus(focusNode[_nextFocus]);
                            } else {
                              _nextFocus = (mListOtpData.length - 1) - 1;
                            }
                          }
                        } else {
                          if (i >= 1) {
                            _nextFocus = i - 1;
                            FocusScope.of(context)
                                .requestFocus(focusNode[_nextFocus]);
                          } else {
                            _nextFocus = 1;
                          }
                        }
                      }
                    },
                  ),
                ),
              );
            }),
      ),
    );
  }

  InputBorder? _getBorder(int i) {
    return textController[i].text.length >= 1
        ? _borderAfterTextChange
        : widget.borderStyle;
  }

  bool _isFilled(int i) {
    return textController[i].text.length >= 1
        ? widget.filledAfterTextChange
        : widget.filled;
  }

  Widget textFieldFill(
      {ValueChanged? onTextChange,
      FocusNode? focusNode,
      TextEditingController? textEditingController,
      InputBorder? border,
      bool? isFilled}) {
    return SizedBox(
      child: TextFormField(
          focusNode: focusNode,
          autofocus: true,
          maxLength: 2,
          showCursor: false,
          scrollPadding: EdgeInsets.all(0),
          cursorWidth: 0,
          enableInteractiveSelection: false,
          autocorrect: false,
          textAlign: TextAlign.center,
          style: widget.textStyle,
          decoration: InputDecoration(
              filled: isFilled,
              border: border,
              fillColor: widget.filledColor,
              isDense: true,
              counterText: ""),
          keyboardType: TextInputType.phone,
          onChanged: onTextChange,
          controller: textEditingController,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ]),
    );
  }

  _singlePinView(int i) {
    return Flexible(
        flex: 3,
        child: Container(
          margin: EdgeInsets.all(4),
          child: Center(
            child: textFieldFill(
              focusNode: focusNode[i],
              textEditingController: textController[i],
              border: _getBorder(i),
              isFilled: _isFilled(i),
              onTextChange: (value) {
                if(value.toString().length > 1 && (i+1 == textController.length  ||textController[i+1].text.length > 0)){
                  textController[i].text = value.toString()[1];
                  if(i+1 == textController.length){
                    _nextFocus = i - 1;
                    FocusScope.of(context)
                        .requestFocus(focusNode[_nextFocus]);
                    Future.delayed(Duration(milliseconds: 2),(){
                      _nextFocus = _nextFocus + 1;
                      FocusScope.of(context)
                          .requestFocus(focusNode[_nextFocus]);
                    });
                  }else{
                    _nextFocus = i + 1;
                    FocusScope.of(context)
                        .requestFocus(focusNode[_nextFocus]);
                  }

                  _otpNumberCallback(i, false);
                }else{
                  _otpNumberCallback(i, false);

                  if (value.toString().length > 0) {
                    if(value.toString().length > 1){
                      _nextFocus = i + 1;
                      FocusScope.of(context)
                          .requestFocus(focusNode[_nextFocus]);
                      textController[i].text = value.toString()[0];
                      textController[i + 1].text = value.toString()[1];
                      if (i + 2 < focusNode.length) {
                        _nextFocus = i + 2;
                        FocusScope.of(context)
                            .requestFocus(focusNode[_nextFocus]);
                      }
                    }else {
                      if (_nextFocus != mListOtpData.length) {
                        _nextFocus = i + 1;
                        if (_nextFocus < mListOtpData.length) {
                          FocusScope.of(context)
                              .requestFocus(focusNode[_nextFocus]);
                        }
                      } else {
                        _nextFocus = (mListOtpData.length - 1) - 1;
                      }
                    }
                  } else {
                    if (i >= 1) {
                      _nextFocus = i - 1;
                      FocusScope.of(context)
                          .requestFocus(focusNode[_nextFocus]);
                    } else {
                      _nextFocus = 1;
                    }
                  }
                }
              },
            ),
          ),
        ));
  }

}

class OtpDefaultData {
  String? code;

  OtpDefaultData(this.code);
}

import 'package:flutter/material.dart';

const arduinoEditorTheme = <String, TextStyle>{
  'root': TextStyle(
    backgroundColor: Color(0xff121b22),
    color: Color(0xfff1f5f9),
    fontSize: 13.5,
    height: 1.45,
    fontFamily: 'monospace',
  ),
  'comment': TextStyle(
    color: Color(0xff60758a),
    fontStyle: FontStyle.italic,
  ),
  'quote': TextStyle(
    color: Color(0xff60758a),
    fontStyle: FontStyle.italic,
  ),
  'doctag': TextStyle(
    color: Color(0xff60758a),
    fontStyle: FontStyle.italic,
  ),
  'keyword': TextStyle(
    color: Color(0xffc084fc),
    fontWeight: FontWeight.w600,
  ),
  'meta': TextStyle(
    color: Color(0xff22d3ee),
    fontWeight: FontWeight.w500,
  ),
  'type': TextStyle(
    color: Color(0xff38bdf8),
    fontWeight: FontWeight.w600,
  ),
  'built_in': TextStyle(
    color: Color(0xff22d3ee),
    fontWeight: FontWeight.w600,
  ),
  'builtin-name': TextStyle(
    color: Color(0xff22d3ee),
  ),
  'function': TextStyle(
    color: Color(0xff38bdf8),
  ),
  'title': TextStyle(
    color: Color(0xff38bdf8),
    fontWeight: FontWeight.w600,
  ),
  'number': TextStyle(
    color: Color(0xfff87171),
    fontWeight: FontWeight.w500,
  ),
  'literal': TextStyle(
    color: Color(0xff22d3ee),
    fontWeight: FontWeight.w500,
  ),
  'string': TextStyle(
    color: Color(0xfffde047),
  ),
  'symbol': TextStyle(
    color: Color(0xff22d3ee),
  ),
  'variable': TextStyle(
    color: Color(0xfff8fafc),
  ),
  'template-variable': TextStyle(
    color: Color(0xfff8fafc),
  ),
  'params': TextStyle(
    color: Color(0xfff8fafc),
  ),
  'attr': TextStyle(
    color: Color(0xff22d3ee),
  ),
  'attribute': TextStyle(
    color: Color(0xff22d3ee),
  ),
  'strong': TextStyle(
    fontWeight: FontWeight.bold,
  ),
  'emphasis': TextStyle(
    fontStyle: FontStyle.italic,
  ),
};

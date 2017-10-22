assert = require 'assert'

mod = require '../src/index.coffee'
Type = require 'type'
type = (t)->new Type t
c = (val, _type)->
  t = new mod.Const
  t.val  = val
  t.type = type _type
  t

describe 'index section', ()->
  describe 'constructor', ()->
    
    for v in "This Const Array_init Hash_init Struct_init Var Bin_op Un_op Fn_call Scope If Switch Loop While For_range For_array For_hash Ret Try Throw Var_decl Class_decl Fn_decl Closure_decl".split /\s+/g
      do (v)->
        it v, ()-> new mod.This
    
  describe 'validate type', ()->
    do ()->
      test = (_t)->
        t = new mod.Var_decl
        t.name = 'a'
        t.type = type _t
        t.validate()
        return
      
      for v in "int float string bool array<int> hash<int> struct{a:int}".split /\s+/g
        do (v)->
          it v, ()-> test v
    
    describe 'throws', ()->
      it 'null', ()->
        t = new mod.Var_decl
        t.name = 'a'
        assert.throws ()-> t.validate()
        return
      
      do ()->
        test = (_t)->
          t = new mod.Var_decl
          t.name = 'a'
          t.type = type _t
          assert.throws ()-> t.validate()
          return
        
        for v in "wtf array<wtf> int<int> int{a:int} float<int> float{a:int} string<int> string{a:int} array array<int>{a:int} hash hash<int>{a:int} struct struct<int>{a:int}".split /\s+/g
          do (v)->
            it v, ()-> test v
  
  describe 'Const', ()->
    describe 'bool', ()->
      it 'true', ()->
        c('true', 'string').validate()
      it 'false', ()->
        c('true', 'string').validate()
      it 'wtf', ()->
        assert.throws ()-> c('wtf', 'bool').validate()
    
    describe 'string', ()->
      it 'ok', ()->
        c('any', 'string').validate()
    
    describe 'int', ()->
      it 'ok', ()->
        c('1', 'int').validate()
      it 'fail string', ()->
        assert.throws ()-> c('a', 'int').validate()
      it 'fail float', ()->
        assert.throws ()-> c('1.1', 'int').validate()
    
    describe 'float', ()->
      it 'int', ()->
        c('1', 'float').validate()
      it 'float', ()->
        c('1.1', 'float').validate()
      it 'fail string', ()->
        assert.throws ()-> c('a', 'float').validate()
    
    it 'wtf', ()->
      assert.throws ()-> c('any', 'wtf').validate()
    
    it 'array<int>', ()->
      assert.throws ()-> c('any', 'array<int>').validate()
  
  int = new mod.Const
  int.val  = '1'
  int.type = type 'int'
  
  float = new mod.Const
  float.val  = '1'
  float.type = type 'float'
  
  string = new mod.Const
  string.val  = '1'
  string.type = type 'string'
  describe 'Array_init', ()->
    a = (type, list)->
      t = new mod.Array_init
      t.type  = type
      t.list  = list
      t
    it 'empty', ()->
      a(type('array<int>'),[]).validate()
    
    it '1 int', ()->
      a(type('array<int>'),[c('1', type('int'))]).validate()
    
    describe 'throws', ()->
      it 'no type', ()->
        assert.throws ()-> a(null,[]).validate()
      
      it 'not array type', ()->
        assert.throws ()-> a(type('string'),[]).validate()
      
      it 'string in array<int>', ()->
        assert.throws ()-> a(type('array<int>'),[c('1', type('string'))]).validate()
  
  describe 'Hash_init', ()->
    h = (type, hash)->
      t = new mod.Hash_init
      t.type  = type
      t.hash  = hash
      t
    it 'empty', ()->
      h(type('hash<int>'),{}).validate()
    
    it '1 int', ()->
      h(type('hash<int>'),{a:c('1', type('int'))}).validate()
    
    describe 'throws', ()->
      it 'no type', ()->
        assert.throws ()-> h(null,{}).validate()
      
      it 'not hash type', ()->
        assert.throws ()-> h(type('string'),{}).validate()
      
      it 'string in hash<int>', ()->
        assert.throws ()-> h(type('hash<int>'),{a:c('1', type('string'))}).validate()
  
  describe 'Struct_init', ()->
    s = (type, hash)->
      t = new mod.Struct_init
      t.type  = type
      t.hash  = hash
      t
    
    it 'a:int', ()->
      s(type('struct{a:int}'),{a:c('1', type('int'))}).validate()
    
    describe 'throws', ()->
      it 'empty', ()->
        s(type('struct{a:int}'),{}).validate()
      
      it 'no type', ()->
        assert.throws ()-> s(null,{}).validate()
      
      it 'not hash type', ()->
        assert.throws ()-> s(type('string'),{}).validate()
      
      it 'string in struct{a:int}', ()->
        assert.throws ()-> s(type('struct{a:int}'),{a:c('1', type('string'))}).validate()
  
  describe 'Var', ()->
    it 'ok', ()->
      scope = new mod.Scope
      scope.stmt_list.push t = new mod.Var_decl
      t.name = 'a'
      t.type = type 'int'
      
      console.log "тут другая проблема, нельзя оставлять висячую переменную"
      scope.stmt_list.push t = new mod.Var
      t.name = 'a'
      t.type = type 'int'
      
      scope.validate()
      
    describe 'throws', ()->
      it 'not declared', ()->
        t = new mod.Var
        t.name = 'a'
        t.type = type 'int'
        assert.throws ()-> t.validate()
      
      it 'invalid id', ()->
        t = new mod.Var
        t.name = '1'
        t.type = type 'int'
        assert.throws ()-> t.validate()
      
      it 'not as declared type', ()->
        scope = new mod.Scope
        scope.stmt_list.push t = new mod.Var_decl
        t.name = 'a'
        t.type = type 'int'
        
        console.log "тут другая проблема, нельзя оставлять висячую переменную"
        scope.stmt_list.push t = new mod.Var
        t.name = 'a'
        t.type = type 'string'
        
        assert.throws ()-> scope.validate()
  
  describe 'Bin_op', ()->
    bo = (a, b, op, _type)->
      t = new mod.Bin_op
      t.a  = a
      t.b  = b
      t.op = op
      t.type = type _type
      t
    
    it '1+1', ()->
      bo(int, int, 'ADD', type 'int').validate()
    
    it '1+1.0', ()->
      bo(int, float, 'ADD', type 'float').validate()
    
    it '1.0+1', ()->
      bo(float, int, 'ADD', type 'float').validate()
    
    it '1.0+1.0', ()->
      bo(float, float, 'ADD', type 'float').validate()
    
    it '"1"+"1"', ()->
      bo(string, string, 'ADD', type 'string').validate()
    
    describe 'throws', ()->
      it 'missing a', ()->
        assert.throws ()-> bo(null, int, 'ADD', type 'int').validate()
      
      it 'missing b', ()->
        assert.throws ()-> bo(int, null, 'ADD', type 'int').validate()
      
      it 'invalid op', ()->
        assert.throws ()-> bo(int, int, 'WTF', type 'int').validate()
      
      it 'int+int != float', ()->
        assert.throws ()-> bo(int, int, 'ADD', type 'float').validate()
      
      it 'string+int', ()->
        assert.throws ()-> bo(string, int, 'ADD', type 'string').validate()
  
  describe 'Bin_op', ()->
    uo = (a, op, _type)->
      t = new mod.Un_op
      t.a  = a
      t.op = op
      t.type = type _type
      t
    
    it '-1', ()->
      uo(int, 'MINUS', type 'int').validate()
    
    it '-1.0', ()->
      uo(float, 'MINUS', type 'float').validate()
    
    describe 'throws', ()->
      it 'missing a', ()->
        assert.throws ()-> uo(null, 'MINUS', type 'int').validate()
      
      it 'invalid op', ()->
        assert.throws ()-> uo(int, 'WTF', type 'int').validate()
      
      it '-int != float', ()->
        assert.throws ()-> uo(int, 'MINUS', type 'float').validate()
      
      it '-string', ()->
        assert.throws ()-> uo(string, 'MINUS', type 'int').validate()
  
  describe 'Fn_call', ()->
    fnc = (fn, list, _type, splat=false)->
      t = new mod.Fn_call
      t.fn = fn
      t.arg_list  = list
      t.splat_fin = splat
      t.type = type _type
      t
    
    fn = (scope, _type)->
      scope.stmt_list.push t = new mod.Var_decl
      t.name = 'a'
      t.type = type _type
      
      t = new mod.Var
      t.name = 'a'
      t.type = type _type
      t
    
    it 'function<void>', ()->
      scope = new mod.Scope
      scope.stmt_list.push fnc(fn(scope, 'function<void>'), [], type 'void')
      scope.validate()
    
    it 'function<void,int>', ()->
      scope = new mod.Scope
      scope.stmt_list.push fnc(fn(scope, 'function<void,int>'), [c('1','int')], type 'void')
      scope.validate()
    
    describe 'throws', ()->
      it 'missing', ()->
        scope = new mod.Scope
        scope.stmt_list.push fnc(null, [], type 'void')
        assert.throws ()-> scope.validate()
      
      it 'WTF', ()->
        scope = new mod.Scope
        scope.stmt_list.push fnc(c('1', 'wtf'), [], type 'void')
        assert.throws ()-> scope.validate()
      
      it 'mismatch1', ()->
        scope = new mod.Scope
        scope.stmt_list.push fnc(fn(scope, 'function<void>'), [], type 'int')
        assert.throws ()-> scope.validate()
      
      it 'mismatch2', ()->
        scope = new mod.Scope
        scope.stmt_list.push fnc(fn(scope, 'function<int>'), [], type 'void')
        assert.throws ()-> scope.validate()
      
      it 'mismatch3', ()->
        scope = new mod.Scope
        scope.stmt_list.push fnc(fn(scope, 'function<int>'), [], type 'float')
        assert.throws ()-> scope.validate()
      
      it 'function<void,int> no int', ()->
        scope = new mod.Scope
        scope.stmt_list.push fnc(fn(scope, 'function<void,int>'), [], type 'void')
        assert.throws ()-> scope.validate()
      
      it 'function<void> extra arg', ()->
        scope = new mod.Scope
        scope.stmt_list.push fnc(fn(scope, 'function<void>'), [c('1','int')], type 'void')
        assert.throws ()-> scope.validate()
      
      it 'function<void,float> with arg int', ()->
        scope = new mod.Scope
        scope.stmt_list.push fnc(fn(scope, 'function<void,float>'), [c('1','int')], type 'void')
        assert.throws ()-> scope.validate()
  
  describe 'If', ()->
    ifc = (cond, list_t, list_f)->
      t = new mod.If
      t.cond = cond
      t.t.stmt_list = list_t
      t.f.stmt_list = list_f
      t
    
    it 'empty', ()->
      ifc(c('true', 'bool'), [], []).validate()
    
    it 'empty with int cond', ()->
      ifc(c('1', 'int'), [], []).validate()
    
    it 'with some body', ()->
      ifc(c('true', 'bool'), [
        (()->
          t = new mod.Var_decl
          t.name = 'a'
          t.type = type 'int'
          t
        )()
      ], []).validate()
    
    describe 'throws', ()->
      it 'no cond', ()->
        assert.throws ()-> ifc(null, [], []).validate()
      
      it 'string cond', ()->
        assert.throws ()-> ifc(c('true', 'string'), [], []).validate()
      
  
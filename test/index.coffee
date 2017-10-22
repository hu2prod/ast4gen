assert = require 'assert'

mod = require '../src/index.coffee'
Type = require 'type'
type = (t)->new Type t

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
      
      for v in "int float string array<int> hash<int> struct{a:int}".split /\s+/g
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
    c = (val, _type)->
      t = new mod.Const
      t.val  = val
      t.type = type _type
      t
    
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
  
  describe 'Array_init', ()->
    c = (val, _type)->
      t = new mod.Const
      t.val  = val
      t.type = type _type
      t
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
    c = (val, _type)->
      t = new mod.Const
      t.val  = val
      t.type = type _type
      t
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
    c = (val, _type)->
      t = new mod.Const
      t.val  = val
      t.type = type _type
      t
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
  
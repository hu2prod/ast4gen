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
        
        for v in "wtf array<wtf> int<int> float<int> string<int> array hash struct".split /\s+/g
          do (v)->
            it v, ()-> test v
      
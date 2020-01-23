assert = require "assert"

mod = require "../src/index.coffee"
Type = require "type"
type = (t)->new Type t
c = (val, _type)->
  t = new mod.Const
  t.val  = val
  t.type = type _type
  t
ifc = (cond, list_t, list_f)->
  t = new mod.If
  t.cond = cond
  t.t.list = list_t
  t.f.list = list_f
  t
_true = c("true", "bool")
_ret = (_t)->
  t = new mod.Ret
  t.t  = _t
  t
_var = (name, _type)->
  t = new mod.Var
  t.name  = name
  t.type  = type _type
  t
_var_decl = (name, _type)->
  t = new mod.Var_decl
  t.name = name
  t.type = type _type
  t
fnd = (name, _type, arg_name_list, scope_list)->
  t = new mod.Fn_decl
  t.name = name
  t.arg_name_list = arg_name_list
  t.type = type _type
  t.scope.list = scope_list
  t
_scope = (scope_list)->
  t = new mod.Scope
  t.list = scope_list
  t
fa = (target, name, _type)->
  t = new mod.Field_access
  t.t = target
  t.name = name
  t.type = type _type
  t

bomb = new mod.Const
empty_scope = new mod.Scope

validate_clone_test = (t)->
  t.validate()
  t.clone().validate()

describe "index section", ()->
  describe "constructor", ()->
    for v in "Const Array_init Hash_init Struct_init Var Bin_op Un_op Field_access Fn_call Scope If Switch Loop Break Continue While For_range For_col Ret Try Throw Var_decl Class_decl Fn_decl".split /\s+/g
      do (v)->
        it v, ()->new mod[v]
    
  describe "validate type", ()->
    do ()->
      test = (_t)->
        t = new mod.Var_decl
        t.name = "a"
        t.type = type _t
        validate_clone_test t
        return
      
      for v in "int float string bool array<int> hash<int> hash_int<int> struct{a:int} function<void> function<void,int>".split /\s+/g
        do (v)->
          it v, ()-> test v
    
    describe "throws", ()->
      it "null", ()->
        t = new mod.Var_decl
        t.name = "a"
        assert.throws ()-> t.validate()
        return
      
      do ()->
        test = (_t)->
          t = new mod.Var_decl
          t.name = "a"
          t.type = type _t
          assert.throws ()-> t.validate()
          return
        
        # struct теперь валидный
        for v in "wtf array<wtf> int<int> int{a:int} float<int> float{a:int} string<int> string{a:int} array array<int>{a:int} hash hash<int>{a:int} struct<int>{a:int} function<> function<void>{a:int}".split /\s+/g
          do (v)->
            it v, ()-> test v
  # ###################################################################################################
  #    expr
  # ###################################################################################################
  describe "Const", ()->
    describe "bool", ()->
      it "true", ()->
        validate_clone_test c("true", "bool")
      it "false", ()->
        validate_clone_test c("true", "bool")
      describe "throws", ()->
        it "wtf", ()->
          assert.throws ()-> c("wtf", "bool").validate()
    
    describe "string", ()->
      it "ok", ()->
        validate_clone_test c("any", "string")
    
    describe "int", ()->
      it "ok", ()->
        validate_clone_test c("1", "int")
      describe "throws", ()->
        it "fail string", ()->
          assert.throws ()-> c("a", "int").validate()
        it "fail float", ()->
          assert.throws ()-> c("1.1", "int").validate()
    
    describe "float", ()->
      it "int", ()->
        validate_clone_test c("1", "float")
      it "float", ()->
        validate_clone_test c("1.0", "float")
      it "float", ()->
        validate_clone_test c("1.1", "float")
      # it "float", ()->
      #   validate_clone_test c("1e+10", "float")
      # it "float", ()->
      #   validate_clone_test c("1e10", "float")
      it "float", ()->
        validate_clone_test c("1e+100", "float")
      it "float", ()->
        validate_clone_test c("1e100", "float")
      describe "throws", ()->
        it "fail string", ()->
          assert.throws ()-> c("a", "float").validate()
    
    describe "throws", ()->
      it "wtf", ()->
        assert.throws ()-> c("any", "wtf").validate()
      
      it "array<int>", ()->
        assert.throws ()-> c("any", "array<int>").validate()
  
  int = new mod.Const
  int.val  = "1"
  int.type = type "int"
  
  float = new mod.Const
  float.val  = "1"
  float.type = type "float"
  
  string = new mod.Const
  string.val  = "1"
  string.type = type "string"
  describe "Array_init", ()->
    a = (type, list)->
      t = new mod.Array_init
      t.type  = type
      t.list  = list
      t
    it "empty", ()->
      validate_clone_test a(type("array<int>"),[])
    
    it "1 int", ()->
      validate_clone_test a(type("array<int>"),[c("1", type("int"))])
    
    describe "throws", ()->
      it "no type", ()->
        assert.throws ()-> a(null,[]).validate()
      
      it "not array type", ()->
        assert.throws ()-> a(type("string"),[]).validate()
      
      it "string in array<int>", ()->
        assert.throws ()-> a(type("array<int>"),[c("1", type("string"))]).validate()
  
  describe "Hash_init", ()->
    h = (type, hash)->
      t = new mod.Hash_init
      t.type  = type
      t.hash  = hash
      t
    it "empty", ()->
      validate_clone_test h(type("hash<int>"),{})
    
    it "1 int", ()->
      validate_clone_test h(type("hash<int>"),{a:c("1", type("int"))})
    
    describe "throws", ()->
      it "no type", ()->
        assert.throws ()-> h(null,{}).validate()
      
      it "not hash type", ()->
        assert.throws ()-> h(type("string"),{}).validate()
      
      it "string in hash<int>", ()->
        assert.throws ()-> h(type("hash<int>"),{a:c("1", type("string"))}).validate()
  
  describe "Struct_init", ()->
    s = (type, hash)->
      t = new mod.Struct_init
      t.type  = type
      t.hash  = hash
      t
    
    it "a:int", ()->
      validate_clone_test s(type("struct{a:int}"),{a:c("1", type("int"))})
    
    it "empty", ()->
      validate_clone_test s(type("struct{a:int}"),{})
    
    it "field access struct", ()->
      t = s(type("struct{a:int}"),{})
      validate_clone_test fa(t, "a", "int")
    
    describe "throws", ()->
      it "no type", ()->
        assert.throws ()-> s(null,{}).validate()
      
      it "not hash type", ()->
        assert.throws ()-> s(type("string"),{}).validate()
      
      it "string in struct{a:int}", ()->
        assert.throws ()-> s(type("struct{a:int}"),{a:c("1", type("string"))}).validate()
      
      it "field access null", ()->
        assert.throws ()-> fa(null, "a", "int").validate()
      
      it "field access wrong type", ()->
        t = s(type("struct{a:int}"),{})
        assert.throws ()-> fa(t, "a", "string").validate()
      
      it "field access empty field", ()->
        t = s(type("struct{a:int}"),{})
        assert.throws ()-> fa(t, "", "int").validate()
      
      it "field access missing field", ()->
        t = s(type("struct{a:int}"),{})
        assert.throws ()-> fa(t, "b", "int").validate()
      
      it "field access const", ()->
        t = c("1", "int")
        assert.throws ()-> fa(t, "b", "int").validate()
  
  describe "Var", ()->
    it "ok", ()->
      scope = new mod.Scope
      scope.list.push t = new mod.Var_decl
      t.name = "a"
      t.type = type "int"
      
      console.log "тут другая проблема, нельзя оставлять висячую переменную"
      scope.list.push t = new mod.Var
      t.name = "a"
      t.type = type "int"
      
      validate_clone_test scope
    
    it "ok with scope no need_nest", ()->
      scope = new mod.Scope
      scope.need_nest = false
      scope.list.push t = new mod.Var_decl
      t.name = "a"
      t.type = type "int"
      
      console.log "тут другая проблема, нельзя оставлять висячую переменную"
      scope.list.push t = new mod.Var
      t.name = "a"
      t.type = type "int"
      
      validate_clone_test scope
      
    describe "throws", ()->
      it "not declared", ()->
        t = new mod.Var
        t.name = "a"
        t.type = type "int"
        assert.throws ()-> t.validate()
      
      it "invalid id", ()->
        t = new mod.Var
        t.name = "1"
        t.type = type "int"
        assert.throws ()-> t.validate()
      
      it "not as declared type", ()->
        scope = new mod.Scope
        scope.list.push t = new mod.Var_decl
        t.name = "a"
        t.type = type "int"
        
        console.log "тут другая проблема, нельзя оставлять висячую переменную"
        scope.list.push t = new mod.Var
        t.name = "a"
        t.type = type "string"
        
        assert.throws ()-> scope.validate()
  
  describe "Bin_op", ()->
    bo = (a, b, op, _type)->
      t = new mod.Bin_op
      t.a  = a
      t.b  = b
      t.op = op
      t.type = type _type
      t
    
    it "1+1", ()->
      validate_clone_test bo(int, int, "ADD", type "int")
    
    it "1+1.0", ()->
      validate_clone_test bo(int, float, "ADD", type "float")
    
    it "1.0+1", ()->
      validate_clone_test bo(float, int, "ADD", type "float")
    
    it "1.0+1.0", ()->
      validate_clone_test bo(float, float, "ADD", type "float")
    
    it '"1"+"1"', ()->
      validate_clone_test bo(string, string, "ADD", type "string")
    
    it "a:int = 1", ()->
      validate_clone_test bo(int, int, "ASSIGN", type "int")
    
    it "a:array<int> = b:array<int>", ()->
      validate_clone_test _scope([
        _var_decl("a", "array<int>")
        _var_decl("b", "array<int>")
        bo(_var("a", "array<int>"), _var("b", "array<int>"), "ASSIGN", type "array<int>")
      ])
    
    it "a:array<int> == b:array<int>", ()->
      validate_clone_test _scope([
        _var_decl("a", "array<int>")
        _var_decl("b", "array<int>")
        bo(_var("a", "array<int>"), _var("b", "array<int>"), "EQ", type "bool")
      ])
    
    it "a:string a[1]", ()->
      validate_clone_test _scope([
        _var_decl("a", "string")
        bo(_var("a", "string"), c("1", "int"), "INDEX_ACCESS", type "string")
      ])
    
    it "a:array<string> a[1]", ()->
      validate_clone_test _scope([
        _var_decl("a", "array<string>")
        bo(_var("a", "array<string>"), c("1", "int"), "INDEX_ACCESS", type "string")
      ])
    
    it 'a:hash<int> a["1"]', ()->
      validate_clone_test _scope([
        _var_decl("a", "hash<int>")
        bo(_var("a", "hash<int>"), c("1", "string"), "INDEX_ACCESS", type "int")
      ])
    
    it "a:hash_int<string> a[1]", ()->
      validate_clone_test _scope([
        _var_decl("a", "hash_int<string>")
        bo(_var("a", "hash_int<string>"), c("1", "int"), "INDEX_ACCESS", type "string")
      ])
    
    describe "throws", ()->
      it "missing a", ()->
        assert.throws ()-> bo(null, int, "ADD", type "int").validate()
      
      it "missing b", ()->
        assert.throws ()-> bo(int, null, "ADD", type "int").validate()
      
      it "invalid op", ()->
        assert.throws ()-> bo(int, int, "WTF", type "int").validate()
      
      it "int+int != float", ()->
        assert.throws ()-> bo(int, int, "ADD", type "float").validate()
      
      it "string+int", ()->
        assert.throws ()-> bo(string, int, "ADD", type "string").validate()
      
      it "a:array<int> = b:int => not array<int>", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "array<int>")
          _var_decl("b", "int")
          bo(_var("a", "array<int>"), _var("b", "int"), "ASSIGN", type "bool")
        ]).validate()
      
      it "a:array<int> = b:array<int> => not array<int>", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "array<int>")
          _var_decl("b", "array<int>")
          bo(_var("a", "array<int>"), _var("b", "array<int>"), "ASSIGN", type "bool")
        ]).validate()
      
      it "a:array<int> == b:array<int> => not bool", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "array<int>")
          _var_decl("b", "int")
          bo(_var("a", "array<int>"), _var("b", "int"), "EQ", type "bool")
        ]).validate()
      
      it "a:array<int> == b:array<int> => not bool", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "array<int>")
          _var_decl("b", "array<int>")
          bo(_var("a", "array<int>"), _var("b", "array<int>"), "EQ", type "array<int>")
        ]).validate()
      
      it "a:string a[1]", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "string")
          bo(_var("a", "string"), c("1", "string"), "INDEX_ACCESS", type "string")
        ]).validate()
      
      it "a:string a[1]", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "string")
          bo(_var("a", "string"), c("1", "int"), "INDEX_ACCESS", type "int")
        ]).validate()
      
      it 'a:array<int> a["1"]', ()->
        assert.throws ()-> _scope([
          _var_decl("a", "array<string>")
          bo(_var("a", "array<string>"), c("1", "string"), "INDEX_ACCESS", type "string")
        ]).validate()
      
      it "a:array<int> a[1] ret int", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "array<string>")
          bo(_var("a", "array<string>"), c("1", "int"), "INDEX_ACCESS", type "int")
        ]).validate()
      
      it "a:hash<int> a[1]", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "hash<int>")
          bo(_var("a", "hash<int>"), c("1", "int"), "INDEX_ACCESS", type "int")
        ]).validate()
      
      it 'a:hash<int> a["1"] ret string', ()->
        assert.throws ()-> _scope([
          _var_decl("a", "hash<int>")
          bo(_var("a", "hash<int>"), c("1", "string"), "INDEX_ACCESS", type "string")
        ]).validate()
      
      it 'a:hash<int> a["1"] ret string', ()->
        assert.throws ()-> _scope([
          _var_decl("a", "int")
          bo(_var("a", "int"), c("1", "string"), "INDEX_ACCESS", type "string")
        ]).validate()
      
      it "a:hash_int<string> a[1] ret int", ()->
        assert.throws ()-> _scope([
          _var_decl("a", "hash_int<string>")
          bo(_var("a", "hash_int<string>"), c("1", "int"), "INDEX_ACCESS", type "int")
        ]).validate()
      
      it 'a:hash_int<string> a["1"] ret string', ()->
        assert.throws ()-> _scope([
          _var_decl("a", "hash_int<string>")
          bo(_var("a", "hash_int<string>"), c("1", "string"), "INDEX_ACCESS", type "string")
        ]).validate()
  
  describe "Bin_op", ()->
    uo = (a, op, _type)->
      t = new mod.Un_op
      t.a  = a
      t.op = op
      t.type = type _type
      t
    
    it "-1", ()->
      validate_clone_test uo(int, "MINUS", type "int")
    
    it "-1.0", ()->
      validate_clone_test uo(float, "MINUS", type "float")
    
    # плохо, но hu2prod
    it "1?", ()->
      validate_clone_test uo(int, "IS_NOT_NULL", type "bool")
    
    describe "throws", ()->
      it "missing a", ()->
        assert.throws ()-> uo(null, "MINUS", type "int").validate()
      
      it "invalid op", ()->
        assert.throws ()-> uo(int, "WTF", type "int").validate()
      
      it "-int != float", ()->
        assert.throws ()-> uo(int, "MINUS", type "float").validate()
      
      it "-string", ()->
        assert.throws ()-> uo(string, "MINUS", type "int").validate()
      
      # плохо, но hu2prod
      it "1? -> int?", ()->
        assert.throws ()-> uo(int, "IS_NOT_NULL", type "int").validate()
  
  describe "Fn_call", ()->
    fnc = (fn, list, _type, splat=false)->
      t = new mod.Fn_call
      t.fn = fn
      t.arg_list  = list
      t.splat_fin = splat
      t.type = type _type
      t
    
    fn = (scope, _type)->
      scope.list.push t = new mod.Var_decl
      t.name = "a"
      t.type = type _type
      
      t = new mod.Var
      t.name = "a"
      t.type = type _type
      t
    
    it "function<void>", ()->
      scope = new mod.Scope
      scope.list.push fnc(fn(scope, "function<void>"), [], type "void")
      validate_clone_test scope
    
    it "function<void,int>", ()->
      scope = new mod.Scope
      scope.list.push fnc(fn(scope, "function<void,int>"), [c("1","int")], type "void")
      validate_clone_test scope
    
    it "function<void> with decl", ()->
      scope = new mod.Scope
      scope.list.push fnd("fn", type("function<void>"), [], [])
      scope.list.push fnc(_var("fn", "function<void>"), [], type "void")
      validate_clone_test scope
    
    it "function<void,int> with decl", ()->
      scope = new mod.Scope
      scope.list.push fnd("fn", type("function<void,int>"), ["a"], [])
      scope.list.push fnc(_var("fn", "function<void,int>"), [c("1","int")], type "void")
      validate_clone_test scope
    
    describe "throws", ()->
      it "missing", ()->
        scope = new mod.Scope
        scope.list.push fnc(null, [], type "void")
        assert.throws ()-> scope.validate()
      
      it "call int", ()->
        scope = new mod.Scope
        scope.list.push fnc(c("1", "int"), [], type "void")
        assert.throws ()-> scope.validate()
      
      it "mismatch1", ()->
        scope = new mod.Scope
        scope.list.push fnc(fn(scope, "function<void>"), [], type "int")
        assert.throws ()-> scope.validate()
      
      it "mismatch2", ()->
        scope = new mod.Scope
        scope.list.push fnc(fn(scope, "function<int>"), [], type "void")
        assert.throws ()-> scope.validate()
      
      it "mismatch3", ()->
        scope = new mod.Scope
        scope.list.push fnc(fn(scope, "function<int>"), [], type "float")
        assert.throws ()-> scope.validate()
      
      it "function<void,int> no int", ()->
        scope = new mod.Scope
        scope.list.push fnc(fn(scope, "function<void,int>"), [], type "void")
        assert.throws ()-> scope.validate()
      
      it "function<void> extra arg", ()->
        scope = new mod.Scope
        scope.list.push fnc(fn(scope, "function<void>"), [c("1","int")], type "void")
        assert.throws ()-> scope.validate()
      
      it "function<void,float> with arg int", ()->
        scope = new mod.Scope
        scope.list.push fnc(fn(scope, "function<void,float>"), [c("1","int")], type "void")
        assert.throws ()-> scope.validate()
  # ###################################################################################################
  #    stmt
  # ###################################################################################################
  describe "If", ()->
    it "basic", ()->
      validate_clone_test ifc(_true, [c("1", "int")], [])
    
    it "basic with int cond", ()->
      validate_clone_test ifc(c("1", "int"), [c("1", "int")], [])
    
    it "with some body", ()->
      validate_clone_test ifc(_true, [
        empty_scope
      ], [])
    
    describe "throws", ()->
      it "empty", ()->
        assert.throws ()-> ifc(_true, [], []).validate()
      
      it "no cond", ()->
        assert.throws ()-> ifc(null, [], []).validate()
      
      it "string cond", ()->
        assert.throws ()-> ifc(c("true", "string"), [], []).validate()
      
      it "bomb true", ()->
        assert.throws ()-> ifc(_true, [bomb], []).validate()
      
      it "bomb false", ()->
        assert.throws ()-> ifc(_true, [], [bomb]).validate()
  
  describe "Switch", ()->
    sw = (cond, hash, list_f=[])->
      t = new mod.Switch
      t.cond = cond
      t.hash = hash
      t.f.list = list_f
      t
    
    it "int", ()->
      validate_clone_test sw(c("1", "int"), {1:empty_scope}, [])
    
    it "string", ()->
      validate_clone_test sw(c("1", "string"), {1:empty_scope}, [])
    
    describe "throws", ()->
      it "empty", ()->
        assert.throws ()-> sw(c("1", "int"), {}, []).validate()
      
      it "no cond", ()->
        assert.throws ()-> sw(null, {1:empty_scope}, []).validate()
      
      it "float cond", ()->
        assert.throws ()-> sw(c("1", "float"), {1:empty_scope}, []).validate()
      
      it "wtf cond", ()->
        assert.throws ()-> sw(c("1", "wtf"), {1:empty_scope}, []).validate()
      
      it "string key with int cond", ()->
        assert.throws ()-> sw(c("1", "int"), {"a":empty_scope}, []).validate()
      
      it "float key with int cond", ()->
        assert.throws ()-> sw(c("1", "int"), {"1.1":empty_scope}, []).validate()
      
      it "hash bomb", ()->
        assert.throws ()-> sw(c("1", "int"), {1:bomb}, []).validate()
      
      it "false bomb", ()->
        assert.throws ()-> sw(c("1", "int"), {1:empty_scope}, [bomb]).validate()
  
  describe "Loop", ()->
    lp = (list)->
      t = new mod.Loop
      t.scope.list = list
      t
    brk = new mod.Break
    cn  = new mod.Continue
    
    it "break", ()->
      validate_clone_test lp([brk])
    
    it "break if pass test", ()->
      validate_clone_test lp([
        ifc(_true, [brk], [])
      ])
    
    it "continue check", ()->
      validate_clone_test lp([brk, cn])
    
    describe "Id pass", ()->
      it "ok", ()->
        validate_clone_test lp([
          (()->
            t = new mod.Var_decl
            t.name = "a"
            t.type = type "int"
            t
          )()
          lp([
            (()->
              t = new mod.Var
              t.name = "a"
              t.type = type "int"
              t
            )()
            brk
          ])
          brk
        ])
      describe "throws", ()->
        it "redeclare", ()->
          assert.throws ()-> lp([
            (()->
              t = new mod.Var_decl
              t.name = "a"
              t.type = type "int"
              t
            )()
            (()->
              t = new mod.Var_decl
              t.name = "a"
              t.type = type "int"
              t
            )()
            brk
          ]).validate()
    
    describe "throws", ()->
      it "no break", ()->
        assert.throws ()-> lp([]).validate()
      
      it "bomb scope", ()->
        assert.throws ()-> lp([bomb]).validate()
      
      it "no break pass through loop", ()->
        assert.throws ()-> lp([ lp([brk]) ]).validate()
      
      it "break with no loop", ()->
        assert.throws ()-> brk.validate()
        assert.throws ()-> cn.validate()
  
  describe "While", ()->
    lp = (cond, list)->
      t = new mod.While
      t.cond = cond
      t.scope.list = list
      t
    brk = new mod.Break
    
    it "ok", ()->
      validate_clone_test lp(_true, [c("1", "int")])
    
    it "break", ()->
      validate_clone_test lp(_true, [brk])
    
    describe "throws", ()->
      it "empty", ()->
        assert.throws ()-> lp(_true, []).validate()
      
      it "no cond", ()->
        assert.throws ()-> lp(null, [bomb]).validate()
      
      it "string cond", ()->
        assert.throws ()-> lp(c("1", "string"), []).validate()
      
      it "bomb scope", ()->
        assert.throws ()-> lp(_true, [bomb]).validate()
  
  describe "For_range", ()->
    fr = (i, a, b, step, list)->
      t = new mod.For_range
      t.i = i
      t.a = a
      t.b = b
      t.step = step
      t.scope.list = list
      t
    
    it "ok", ()->
      validate_clone_test _scope([
        _var_decl("i", "int")
        fr(_var("i", "int"), c("1", "int"), c("10", "int"), null, [
          c("0", "int")
        ])
      ])
    
    it "step", ()->
      validate_clone_test _scope([
        _var_decl("i", "int")
        fr(_var("i", "int"), c("1", "int"), c("10", "int"), c("2", "int"), [
          c("0", "int")
        ])
      ])
    
    it "float step", ()->
      validate_clone_test _scope([
        _var_decl("i", "float")
        fr(_var("i", "float"), c("1", "float"), c("10", "float"), c("2", "float"), [
          c("0", "int")
        ])
      ])
      
    it "float iterator int range int step", ()->
      validate_clone_test _scope([
        _var_decl("i", "float")
        fr(_var("i", "float"), c("1", "int"), c("10", "int"), c("2", "int"), [
          c("0", "int")
        ])
      ])
    
    it "break", ()->
      validate_clone_test _scope([
        _var_decl("i", "int")
        fr(_var("i", "int"), c("1", "int"), c("10", "int"), null, [
          new mod.Break
        ])
      ])
    
    describe "throws", ()->
      it "string iterator", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "string")
          fr(_var("i", "string"), c("1", "int"), c("10", "int"), null, [
            c("0", "int")
          ])
        ]).validate()
      
      it "string a", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "int")
          fr(_var("i", "int"), c("1", "string"), c("10", "int"), null, [
            c("0", "int")
          ])
        ]).validate()
      
      it "string b", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "int")
          fr(_var("i", "int"), c("1", "int"), c("10", "string"), null, [
            c("0", "int")
          ])
        ]).validate()
       
      it "missing iterator", ()->
        assert.throws ()-> _scope([
          fr(null, c("1", "int"), c("10", "int"), null, [
            c("0", "int")
          ])
        ]).validate()
      
      it "missing a", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "int")
          fr(_var("i", "int"), null, c("10", "int"), null, [
            c("0", "int")
          ])
        ]).validate()
      
      it "missing b", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "int")
          fr(_var("i", "int"), c("1", "int"), null, null, [
            c("0", "int")
          ])
        ]).validate()
      
      it "string step", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "int")
          fr(_var("i", "int"), c("1", "int"), c("10", "int"), c("2", "string"), [
            c("0", "int")
          ])
        ]).validate()
      
      it "int iterator float step", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "int")
          fr(_var("i", "int"), c("1", "int"), c("10", "int"), c("2", "float"), [
            c("0", "int")
          ])
        ]).validate()
      
      it "int iterator float range a", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "int")
          fr(_var("i", "int"), c("1", "float"), c("10", "int"), null, [
            c("0", "int")
          ])
        ]).validate()
      
      it "int iterator float range b", ()->
        assert.throws ()-> _scope([
          _var_decl("i", "int")
          fr(_var("i", "int"), c("1", "int"), c("10", "float"), null, [
            c("0", "int")
          ])
        ]).validate()
  
  describe "For_col", ()->
    fc = (k, v, _t, list)->
      t = new mod.For_col
      t.k = k
      t.v = v
      t.t = _t
      t.scope.list = list
      t
    
    it "ok", ()->
      validate_clone_test _scope([
        _var_decl("t", "array<string>")
        _var_decl("k", "int")
        _var_decl("v", "string")
        fc(_var("k", "int"), _var("v", "string"), _var("t", "array<string>"), [
          c("0", "int")
        ])
      ])
    
    it "no k", ()->
      validate_clone_test _scope([
        _var_decl("t", "array<string>")
        _var_decl("k", "int")
        _var_decl("v", "string")
        fc(null, _var("v", "string"), _var("t", "array<string>"), [
          c("0", "int")
        ])
      ])
    
    it "no v", ()->
      validate_clone_test _scope([
        _var_decl("t", "array<string>")
        _var_decl("k", "int")
        _var_decl("v", "string")
        fc(_var("k", "int"), null, _var("t", "array<string>"), [
          c("0", "int")
        ])
      ])
    
    it "ok hash", ()->
      validate_clone_test _scope([
        _var_decl("t", "hash<int>")
        _var_decl("k", "string")
        _var_decl("v", "int")
        fc(_var("k", "string"), _var("v", "int"), _var("t", "hash<int>"), [
          c("0", "int")
        ])
      ])
    
    it "no k hash", ()->
      validate_clone_test _scope([
        _var_decl("t", "hash<int>")
        _var_decl("k", "string")
        _var_decl("v", "int")
        fc(null, _var("v", "int"), _var("t", "hash<int>"), [
          c("0", "int")
        ])
      ])
    
    it "no v hash", ()->
      validate_clone_test _scope([
        _var_decl("t", "hash<int>")
        _var_decl("k", "string")
        _var_decl("v", "int")
        fc(_var("k", "string"), null, _var("t", "hash<int>"), [
          c("0", "int")
        ])
      ])
    
    it "break", ()->
      validate_clone_test _scope([
        _var_decl("t", "array<string>")
        _var_decl("k", "int")
        _var_decl("v", "string")
        fc(_var("k", "int"), _var("v", "string"), _var("t", "array<string>"), [
          new mod.Break
        ])
      ])
    
    describe "throws", ()->
      it "no target", ()->
        assert.throws ()-> _scope([
          _var_decl("t", "array<string>")
          _var_decl("k", "int")
          _var_decl("v", "string")
          fc(_var("k", "int"), _var("v", "string"), null, [
            c("0", "int")
          ])
        ]).validate()
      
      it "target int", ()->
        assert.throws ()-> _scope([
          _var_decl("t", "int")
          _var_decl("k", "int")
          _var_decl("v", "string")
          fc(_var("k", "int"), _var("v", "string"), _var("t", "int"), [
            c("0", "int")
          ])
        ]).validate()
      
      it "not k and v", ()->
        assert.throws ()-> _scope([
          _var_decl("t", "array<string>")
          _var_decl("k", "int")
          _var_decl("v", "string")
          fc(null, null, _var("t", "array<string>"), [
            c("0", "int")
          ])
        ]).validate()
      
      it "wrong k type array", ()->
        assert.throws ()-> _scope([
          _var_decl("t", "array<string>")
          _var_decl("k", "string")
          _var_decl("v", "string")
          fc(_var("k", "string"), _var("v", "string"), _var("t", "array<string>"), [
            c("0", "int")
          ])
        ]).validate()
      
      it "wrong k type hash", ()->
        assert.throws ()-> _scope([
          _var_decl("t", "hash<int>")
          _var_decl("k", "int")
          _var_decl("v", "int")
          fc(_var("k", "int"), _var("v", "int"), _var("t", "hash<int>"), [
            c("0", "int")
          ])
        ]).validate()
      
      it "wrong v type", ()->
        assert.throws ()-> _scope([
          _var_decl("t", "array<string>")
          _var_decl("k", "int")
          _var_decl("v", "int")
          fc(_var("k", "int"), _var("v", "int"), _var("t", "array<string>"), [
            c("0", "int")
          ])
        ]).validate()
  
  describe "Fn_decl", ()->
    ret = new mod.Ret
    it "empty", ()->
      validate_clone_test fnd("fn", type("function<void>"), [], [])
    
    it "1 param", ()->
      validate_clone_test fnd("fn", type("function<void,int>"), ["a"], [])
    
    it "1 param return", ()->
      validate_clone_test fnd("fn", type("function<int,int>"), ["a"], [
        _ret(_var("a", "int"))
      ])
    
    it "1 param + return", ()->
      validate_clone_test fnd("fn", type("function<void,int>"), ["a"], [
        ret
      ])
    
    describe "throws", ()->
      it "return out of fn_decl scope not allowed", ()->
        assert.throws ()-> lp([ret]).validate()
      
      it "1 param + return int but void expected", ()->
        assert.throws ()-> fnd("fn", type("function<void,int>"), ["a"], [
          _ret(c("1", "int"))
        ]).validate()
      
      it "1 param + return void but int expected", ()->
        assert.throws ()-> fnd("fn", type("function<int,int>"), ["a"], [
          ret
        ]).validate()
      
      it "no name", ()->
        t = fnd("fn", type("function<void>"), [], [])
        t.name = ""
        assert.throws ()-> t.validate()
      
      it "arg name miss", ()->
        assert.throws ()-> fnd("fn", type("function<void,int>"), [], []).validate()
      
      it "not function type", ()->
        assert.throws ()-> fnd("fn", type("array<int>"), [], []).validate()
      
      it "alone ret", ()->
        assert.throws ()-> _ret().validate()
  
  describe "Class_decl", ()->
    cls = (name, scope_list)->
      t = new mod.Class_decl
      t.name = name
      t.scope.list = scope_list
      t
    
    it "empty", ()->
      validate_clone_test cls("A", [])
    
    it "prop", ()->
      validate_clone_test cls("A", [
        _var_decl("prop", "int")
      ])
    
    it "fn", ()->
      validate_clone_test cls("A", [
        fnd("fn", type("function<void>"), [], [])
      ])
    
    it "fn this", ()->
      validate_clone_test _scope([
        cls("A", [
          fnd("fn", type("function<void>"), [], [
            (()->
              t = new mod.Var
              t.name = "this"
              t.type = type "A"
              t
            )()
          ])
        ])
      ])
    
    it "fn this", ()->
      validate_clone_test _scope([
        cls("A", [
          fnd("fn", type("function<void>"), [], [
            (()->
              t = new mod.Var
              t.name = "this"
              t.type = type "A"
              t
            )()
          ])
        ])
      ])
    
    it "field access class", ()->
      validate_clone_test _scope([
        cls("A", [
          _var_decl("prop", "int")
        ])
        _var_decl("a", "A")
        fa(_var("a", "A"), "prop", "int")
      ])
    
    it "field access in method over this", ()->
      validate_clone_test _scope([
        cls("A", [
          _var_decl("prop", "int")
          fnd("fn", type("function<void>"), [], [
            fa(_var("this", "A"), "prop", "int")
          ])
        ])
      ])
    
    it "new", ()->
      validate_clone_test _scope([
        cls("A", [])
        _var_decl("a" , "A")
        fa(_var("a", "A"), "new", "function<A>")
      ])
    
    describe "throws", ()->
      it "no name", ()->
        assert.throws ()-> cls("", []).validate()
      
      it "reregister", ()->
        assert.throws ()->
          _scope([
            cls("A", [])
            cls("A", [])
          ]).validate()
    
      it "new bool", ()->
        assert.throws ()-> _scope([
          _var_decl("a" , "bool")
          fa(_var("a", "bool"), "new", "function<bool>")
        ]).validate()
      
      # Потом
      # it "wrong this type", ()->
      #   _scope([
      #     cls("A", [
      #       _var_decl("prop", "int")
      #       fnd("fn", type("function<void>"), [], [
      #         _var("this", "int")
      #       ])
      #     ])
      #   ]).validate()
      
      it "garbage", ()->
        assert.throws ()-> cls("A", [
          c("1", "int")
        ]).validate()
      
      it "field access class wrong field", ()->
        assert.throws ()-> _scope([
          cls("A", [
            _var_decl("prop", "int")
          ])
          _var_decl("a", "A")
          fa(_var("a", "A"), "wtf", "int")
        ]).validate()
      
  describe "array api", ()->
    it "length_get", ()->
      validate_clone_test _scope([
        _var_decl("a", "array<int>")
        fa(_var("a", "array<int>"), "length_get", "function<int>")
      ])
    
    it "length_get", ()->
      validate_clone_test _scope([
        _var_decl("a", "array<int>")
        fa(_var("a", "array<int>"), "pop", "function<int>")
      ])
    
    it "new", ()->
      validate_clone_test _scope([
        _var_decl("a", "array<int>")
        fa(_var("a", "array<int>"), "new", "function<array<int>>")
      ])
    
  describe "hash api", ()->
    it "new", ()->
      validate_clone_test _scope([
        _var_decl("a", "hash<int>")
        fa(_var("a", "hash<int>"), "new", "function<hash<int>>")
      ])
  
    
  describe "hash_int api", ()->
    it "new", ()->
      validate_clone_test _scope([
        _var_decl("a", "hash_int<int>")
        fa(_var("a", "hash_int<int>"), "new", "function<hash_int<int>>")
      ])
    
    it "idx", ()->
      validate_clone_test _scope([
        _var_decl("a", "hash_int<string>")
        fa(_var("a", "hash_int<string>"), "idx", "function<string,int>")
      ])
  

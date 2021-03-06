require "fy"
Type = require "type"
module = @

void_type = new Type "void"
@type_actualize = type_actualize = (t, root)->
  t = t.clone()
  walk = (_t)->
    if reg_ret = /^_(\d+)$/.exec _t.main
      [_skip, idx] = reg_ret
      if !root.nest_list[idx]
        # TODO make some test
        ### !pragma coverage-skip-block ###
        throw new Error "can't resolve #{_t} because root type '#{root}' cas no nest_list[#{idx}]"
      return root.nest_list[idx].clone()
    for v,k in _t.nest_list
      _t.nest_list[k] = walk v
    for k,v of _t.field_hash
      # Прим. пока эта часть еще никем не используется
      # TODO make some test
      ### !pragma coverage-skip-block ###
      _t.field_hash[k] = walk v
    _t
  walk t

type_validate = (t, ctx)->
  if !t
    throw new Error "Type validation error line=#{@line} pos=#{@pos}. type is missing"
  # if !ctx # JUST for debug
    # throw new Error "WTF"
  switch t.main
    when "void", "int", "float", "string", "bool"
      if t.nest_list.length != 0
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} can't have nest_list"
      if 0 != h_count t.field_hash
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} can't have field_hash"
    
    when "array", "hash_int"
      if t.nest_list.length != 1
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} must have nest_list 1"
      if 0 != h_count t.field_hash
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} can't have field_hash"
    
    when "hash"
      if t.nest_list.length != 1
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} must have nest_list 1"
      if 0 != h_count t.field_hash
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} can't have field_hash"
    
    when "struct"
      if t.nest_list.length != 0
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} must have nest_list 0"
      # if 0 == h_count t.field_hash
      #   throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} must have field_hash"
    
    when "function"
      if t.nest_list.length == 0
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} must have at least nest_list 1 (ret type)"
      if 0 != h_count t.field_hash
        throw new Error "Type validation error line=#{@line} pos=#{@pos}. #{t.main} can't have field_hash"
      ""
      # TODO defined types ...
    
    else
      if !ctx.check_type t.main
        throw new Error "unknown type '#{t}'"
  for v,k in t.nest_list
    # continue if k == 0 and t.main == "function" and v.main == "void" # it's ok
    type_validate v, ctx
  
  for k,v of t.field_hash
    type_validate v, ctx
  
  return

wrap = (_prepared_field2type)->
  ret = new module.Class_decl
  ret._prepared_field2type = _prepared_field2type
  ret

@default_var_hash_gen = ()->
  ret =
    "true" : new Type "bool"
    "false": new Type "bool"

@default_type_hash_gen = ()->
  ret =
    "array" : wrap
      remove_idx : new Type "function<void, int>"
      length_get : new Type "function<int>"
      length_set : new Type "function<void, int>"
      pop        : new Type "function<_0>"
      push       : new Type "function<void,_0>"
      slice      : new Type "function<array<_0>,int,int>" # + option
      remove     : new Type "function<void,_0>"
      idx        : new Type "function<int,_0>"
      has        : new Type "function<bool,_0>"
      append     : new Type "function<void,array<_0>>"
      clone      : new Type "function<array<_0>>"
      sort_i     : new Type "function<void,function<int,_0,_0>>"
      sort_f     : new Type "function<void,function<float,_0,_0>>"
      sort_by_i  : new Type "function<void,function<int,_0>>"
      sort_by_f  : new Type "function<void,function<float,_0>>"
      sort_by_s  : new Type "function<void,function<string,_0>>"
    
    "hash_int" : wrap
      add        : new Type "function<void,int,_0>"
      remove_idx : new Type "function<void,int>"
      idx        : new Type "function<_0,int>"

class @Validation_context
  parent    : null
  executable: false
  breakable : false
  returnable: false
  type_hash  : {}
  var_hash  : {}
  line  : 0
  pos   : 0
  constructor:()->
    @type_hash = module.default_type_hash_gen()
    @var_hash  = module.default_var_hash_gen()
  
  seek_non_executable_parent : ()->
    if @executable
      @parent.seek_non_executable_parent()
    else
      @
  
  mk_nest : (pass_breakable)->
    ret = new module.Validation_context
    ret.parent = @
    ret.returnable= @returnable
    ret.executable= @executable
    ret.breakable = @breakable if pass_breakable
    ret
  
  check_type : (id)->
    return found if found = @type_hash[id]
    if @parent
      return @parent.check_type id
    return null
  
  
  check_id : (id)->
    return found if found = @var_hash[id]
    if @parent
      return @parent.check_id id
    return null
  
  check_id_decl : (id)->
    @var_hash[id]
  

# ###################################################################################################
#    expr
# ###################################################################################################
# TODO array init
# TODO hash init
# TODO interpolated string init
class @Const
  val   : ""
  type  : null
  line  : 0
  pos   : 0
  validate : (ctx = new module.Validation_context)->
    type_validate @type, ctx
    switch @type.main
      when "bool"
        unless @val in ["true", "false"]
          throw new Error "Const validation error line=#{@line} pos=#{@pos}. '#{@val}' can't be bool"
      
      when "int"
        if parseInt(@val).toString() != @val
          throw new Error "Const validation error line=#{@line} pos=#{@pos}. '#{@val}' can't be int"
      
      when "float"
        val = @val
        val = val.replace(/\.0+$/, "")
        val = val.replace(/e(\d)/i, "e+$1")
        if parseFloat(val).toString() != val
          throw new Error "Const validation error line=#{@line} pos=#{@pos}. '#{@val}' can't be float"
      
      when "string"
        "nothing"
        # string will be quoted and escaped
      # when "char"
      
      else
        throw new Error "can't implement constant type '#{@type}'"
    
    return
  
  clone : ()->
    ret = new module.Const
    ret.val   = @val
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Array_init
  list  : []
  type  : null
  line  : 0
  pos   : 0
  constructor:()->
    @list = []
  
  validate : (ctx = new module.Validation_context)->
    type_validate @type, ctx
    if @type.main != "array"
      throw new Error "Array_init validation error line=#{@line} pos=#{@pos}. type must be array but '#{@type}' found"
    
    cmp_type = @type.nest_list[0]
    
    for v,k in @list
      v.validate(ctx)
      if !v.type.cmp cmp_type
        throw new Error "Array_init validation error line=#{@line} pos=#{@pos}. key '#{k}' must be type '#{cmp_type}' but '#{v.type}' found"
    
    return
  
  clone : ()->
    ret = new module.Array_init
    for v in @list
      ret.list.push v.clone()
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Hash_init
  hash  : {}
  type  : null
  line  : 0
  pos   : 0
  constructor:()->
    @hash = {}
  
  validate : (ctx = new module.Validation_context)->
    type_validate @type, ctx
    if @type.main != "hash"
      throw new Error "Hash_init validation error line=#{@line} pos=#{@pos}. type must be hash but '#{@type}' found"
    
    for k,v of @hash
      v.validate(ctx)
    
    cmp_type = @type.nest_list[0]
    for k,v of @hash
      if !v.type.cmp cmp_type
        throw new Error "Hash_init validation error line=#{@line} pos=#{@pos}. key '#{k}' must be type '#{cmp_type}' but '#{v.type}' found"
  
    return
  
  clone : ()->
    ret = new module.Hash_init
    for k,v of @hash
      ret.hash[k] = v.clone()
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Struct_init
  hash  : {}
  type  : null
  line  : 0
  pos   : 0
  constructor:()->
    @hash = {}
  
  validate : (ctx = new module.Validation_context)->
    type_validate @type, ctx
    if @type.main != "struct"
      throw new Error "Struct_init validation error line=#{@line} pos=#{@pos}. type must be struct but '#{@type}' found"
      
    for k,v of @hash
      v.validate(ctx)
      if !v.type.cmp cmp_type = @type.field_hash[k]
        throw new Error "Struct_init validation error line=#{@line} pos=#{@pos}. key '#{k}' must be type '#{cmp_type}' but '#{v.type}' found"
    
    return
  
  clone : ()->
    ret = new module.Struct_init
    for k,v of @hash
      ret.hash[k] = v.clone()
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Var
  name : ""
  type  : null
  line  : 0
  pos   : 0
  validate : (ctx = new module.Validation_context)->
    if !/^[_a-z][_a-z0-9]*$/i.test @name
      throw new Error "Var validation error line=#{@line} pos=#{@pos}. invalid identifier '#{@name}'"
    type_validate @type, ctx
    
    var_decl = ctx.check_id(@name)
    if !var_decl
      throw new Error "Var validation error line=#{@line} pos=#{@pos}. Id '#{@name}' not defined"
    {type} = var_decl
    if !@type.cmp type
      throw new Error "Var validation error line=#{@line} pos=#{@pos}. Var type !+ Var_decl type '#{@type}' != #{type}"
    return
  
  clone : ()->
    ret = new module.Var
    ret.name  = @name
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

@allowed_bin_op_hash =
  ADD : true
  SUB : true
  MUL : true
  DIV : true
  DIV_INT: true
  MOD : true
  POW : true
  
  BIT_AND : true
  BIT_OR  : true
  BIT_XOR : true
  
  BOOL_AND : true
  BOOL_OR  : true
  BOOL_XOR : true
  
  SHR : true
  SHL : true
  LSR : true # логический сдвиг вправо >>>
  
  ASSIGN : true
  ASS_ADD : true
  ASS_SUB : true
  ASS_MUL : true
  ASS_DIV : true
  ASS_DIV_INT: true
  ASS_MOD : true
  ASS_POW : true
  
  ASS_SHR : true
  ASS_SHL : true
  ASS_LSR : true # логический сдвиг вправо >>>
  
  ASS_BIT_AND : true
  ASS_BIT_OR  : true
  ASS_BIT_XOR : true
  
  ASS_BOOL_AND : true
  ASS_BOOL_OR  : true
  ASS_BOOL_XOR : true
  
  EQ : true
  NE : true
  GT : true
  LT : true
  GTE: true
  LTE: true
  
  INDEX_ACCESS : true # a[b] как бинарный оператор

@assign_bin_op_hash = 
  ASSIGN : true
  ASS_ADD : true
  ASS_SUB : true
  ASS_MUL : true
  ASS_DIV : true
  ASS_MOD : true
  ASS_POW : true
  
  ASS_SHR : true
  ASS_SHL : true
  ASS_LSR : true # логический сдвиг вправо >>>
  
  ASS_BIT_AND : true
  ASS_BIT_OR  : true
  ASS_BIT_XOR : true
  
  ASS_BOOL_AND : true
  ASS_BOOL_OR  : true
  ASS_BOOL_XOR : true

@bin_op_ret_type_hash_list =
  DIV : [
    ["int", "int", "float"]
    ["int", "float", "float"]
    ["float", "int", "float"]
    ["float", "float", "float"]
  ]
  DIV_INT : [
    ["int", "int", "int"]
    ["int", "float", "int"]
    ["float", "int", "int"]
    ["float", "float", "int"]
  ]
# mix int float -> higher
for v in "ADD SUB MUL POW".split  /\s+/g
  @bin_op_ret_type_hash_list[v] = [
    ["int", "int", "int"]
    ["int", "float", "float"]
    ["float", "int", "float"]
    ["float", "float", "float"]
  ]
# pure int
for v in "MOD BIT_AND BIT_OR BIT_XOR SHR SHL LSR".split  /\s+/g
  @bin_op_ret_type_hash_list[v] = [["int", "int", "int"]]
# pure bool
for v in "BOOL_AND BOOL_OR BOOL_XOR".split  /\s+/g
  @bin_op_ret_type_hash_list[v] = [["bool", "bool", "bool"]]
# special string magic
@bin_op_ret_type_hash_list.ADD.push ["string", "string", "string"]
@bin_op_ret_type_hash_list.MUL.push ["string", "int", "string"]
# equal ops =, cmp
for v in "ASSIGN".split  /\s+/g
  @bin_op_ret_type_hash_list[v] = [
    ["int", "int", "int"]
    ["bool", "bool", "bool"]
    ["float", "float", "float"]
    ["string", "string", "string"]
  ]
for v in "EQ NE GT LT GTE LTE".split  /\s+/g
  @bin_op_ret_type_hash_list[v] = [
    ["int", "int", "bool"]
    ["float", "float", "bool"]
    ["string", "string", "bool"]
  ]
str_list = """
ADD
SUB
MUL
DIV
DIV_INT
MOD
POW

SHR
SHL
LSR

BIT_AND 
BIT_OR  
BIT_XOR 

BOOL_AND
BOOL_OR 
BOOL_XOR
"""
for v in str_list.split  /\s+/g
  table = @bin_op_ret_type_hash_list[v]
  table = table.filter (row)->row[0] == row[2]
  table = table.map (t)-> t.clone() # make safe
  @bin_op_ret_type_hash_list["ASS_#{v}"] = table


class @Bin_op
  a     : null
  b     : null
  op    : null
  type  : null
  line  : 0
  pos   : 0
  validate : (ctx = new module.Validation_context)->
    if !@a
      throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. a missing"
    @a.validate(ctx)
    if !@b
      throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. b missing"
    @b.validate(ctx)
    
    type_validate @type, ctx
    
    if !module.allowed_bin_op_hash[@op]
      throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. Invalid op '#{@op}'"
    
    found = false
    if list = module.bin_op_ret_type_hash_list[@op]
      for v in list
        continue if v[0] != @a.type.toString()
        continue if v[1] != @b.type.toString()
        found = true
        if v[2] != @type.toString()
          throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} with types #{@a.type} #{@b.type} should produce type #{v[2]} but #{@type} found"
        break
    
    # extra cases
    if !found
      if @op == "ASSIGN"
        if @a.type.cmp @b.type
          if @a.type.cmp @type
            found = true
          else
            throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. #{@op} a=b=[#{@a.type}] must have return type '#{@a.type}'"
      
      else if @op in ["EQ", "NE"]
        if @a.type.cmp @b.type
          if @type.main == "bool"
            found = true
          else
            throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. #{@op} a=b=[#{@a.type}] must have return type bool"
      else if @op == "INDEX_ACCESS"
        switch @a.type.main
          when "string"
            if @b.type.main == "int"
              found = true
            else
              throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} #{@a.type} #{@b.type} ret type must be int"
            if @type.main == "string"
              found = true
            else
              throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} #{@a.type} #{@b.type} ret type must be string"
          
          when "array"
            if @b.type.main == "int"
              found = true
            else
              throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} #{@a.type} #{@b.type} ret type must be int"
            if @type.cmp @a.type.nest_list[0]
              found = true
            else
              throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} #{@a.type} #{@b.type} ret type must be #{@a.type.nest_list[0]} but #{@type} found"
          
          when "hash"
            if @b.type.main == "string"
              found = true
            else
              throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} #{@a.type} #{@b.type} ret type must be string"
            if @type.cmp @a.type.nest_list[0]
              found = true
            else
              throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} #{@a.type} #{@b.type} ret type must be #{@a.type.nest_list[0]} but #{@type} found"
          
          when "hash_int"
            if @b.type.main == "int"
              found = true
            else
              throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} #{@a.type} #{@b.type} ret type must be int"
            if @type.cmp @a.type.nest_list[0]
              found = true
            else
              throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. bin_op=#{@op} #{@a.type} #{@b.type} ret type must be #{@a.type.nest_list[0]} but #{@type} found"
          
          else
            throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. Can't apply bin_op=#{@op} to #{@a.type} #{@b.type}"
    
    if !found
      throw new Error "Bin_op validation error line=#{@line} pos=#{@pos}. Can't apply bin_op=#{@op} to #{@a.type} #{@b.type}"
    
    return
  
  clone : ()->
    ret = new module.Bin_op
    ret.a     = @a.clone()
    ret.b     = @b.clone()
    ret.op    = @op
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

@allowed_un_op_hash =
  INC_RET : true
  RET_INC : true
  DEC_RET : true
  RET_DEC : true
  BOOL_NOT: true
  BIT_NOT : true
  MINUS   : true
  PLUS    : true # parseFloat
  IS_NOT_NULL : true
  # new ?
  # delete ?

@un_op_ret_type_hash_list =
  INC_RET : [
    ["int", "int"]
  ]
  RET_INC : [
    ["int", "int"]
  ]
  DEC_RET : [
    ["int", "int"]
  ]
  RET_DEC : [
    ["int", "int"]
  ]
  BOOL_NOT : [
    ["bool", "bool"]
  ]
  BIT_NOT : [
    ["int", "int"]
  ]
  MINUS : [
    ["int", "int"]
    ["float", "float"]
  ]
  PLUS : [
    ["string", "float"]
  ]
class @Un_op
  a     : null
  op    : null
  type  : null
  line  : 0
  pos   : 0
  validate : (ctx = new module.Validation_context)->
    if !@a
      throw new Error "Un_op validation error line=#{@line} pos=#{@pos}. a missing"
    @a.validate(ctx)
    
    type_validate @type, ctx
    
    if !module.allowed_un_op_hash[@op]
      throw new Error "Un_op validation error line=#{@line} pos=#{@pos}. Invalid op '#{@op}'"
    
    list = module.un_op_ret_type_hash_list[@op]
    found = false
    if list
      for v in list
        continue if v[0] != @a.type.toString()
        found = true
        if v[1] != @type.toString()
          throw new Error "Un_op validation error line=#{@line} pos=#{@pos}. un_op=#{@op} with type #{@a.type} should produce type #{v[1]} but #{@type} found"
        break
    if @op == "IS_NOT_NULL"
      if @type.main != "bool"
        throw new Error "Un_op validation error line=#{@line} pos=#{@pos}. un_op=#{@op} with type #{@a.type} should produce type bool but #{@type} found"
      found = true
    if !found
      throw new Error "Un_op validation error line=#{@line} pos=#{@pos}. Can't apply un_op=#{@op} to #{@a.type}"
    
    return
  
  clone : ()->
    ret = new module.Un_op
    ret.a     = @a.clone()
    ret.op    = @op
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Field_access
  t     : null
  name  : ""
  type  : null
  line  : 0
  pos   : 0
  
  validate : (ctx = new module.Validation_context)->
    if !@t
      throw new Error "Field_access validation error line=#{@line} pos=#{@pos}. Missing target"
    @t.validate(ctx)
    
    if !@name
      throw new Error "Field_access validation error line=#{@line} pos=#{@pos}. Missing name"
    
    type_validate @type, ctx
    
    if @name == "new"
      if @t.type.main in ["bool", "int", "float", "string"]
        throw new Error "Field_access validation error line=#{@line} pos=#{@pos}. Access to missing field '#{@name}' in '#{@t.type}'."
      nest_type = new Type "function"
      nest_type.nest_list[0] = @t.type
    else if @t.type.main == "struct"
      if !nest_type = @t.type.field_hash[@name]
        throw new Error "Field_access validation error line=#{@line} pos=#{@pos}. Access to missing field '#{@name}' in '#{@t.type}'. Possible keys [#{Object.keys(@t.type.field_hash).join ', '}]"
    else
      class_decl = ctx.check_type @t.type.main
      if !nest_type = class_decl._prepared_field2type[@name]
        throw new Error "Field_access validation error line=#{@line} pos=#{@pos}. Access to missing class field '#{@name}' in '#{@t.type}'. Possible keys [#{Object.keys(class_decl._prepared_field2type).join ', '}]"
    
    nest_type = type_actualize nest_type, @t.type
    
    if !@type.cmp nest_type
      throw new Error "Field_access validation error line=#{@line} pos=#{@pos}. Access to field '#{@name}' with type '#{nest_type}' but result '#{@type}'"
    
    return
  
  clone : ()->
    ret = new module.Field_access
    ret.t     = @t.clone()
    ret.name  = @name
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Fn_call
  fn        : null
  arg_list  : []
  splat_fin : false
  type      : null
  line  : 0
  pos   : 0
  constructor:()->
    @arg_list = []
  
  validate : (ctx = new module.Validation_context)->
    if !@fn
      throw new Error "Fn_call validation error line=#{@line} pos=#{@pos}. fn missing"
    @fn.validate(ctx)
    if @fn.type.main != "function"
      throw new Error "Fn_call validation error line=#{@line} pos=#{@pos}. Can't call type '@fn.type'. You can call only function"
    
    if !@type.cmp void_type
      type_validate @type, ctx
    
    if !@type.cmp @fn.type.nest_list[0]
      throw new Error "Fn_call validation error line=#{@line} pos=#{@pos}. Return type and function decl return type doesn't match #{@fn.type.nest_list[0]} != #{@type}"
    
    if @fn.type.nest_list.length-1 != @arg_list.length
      throw new Error "Fn_call validation error line=#{@line} pos=#{@pos}. Expected arg count=#{@fn.type.nest_list.length-1} found=#{@arg_list.length}"
    
    for arg,k in @arg_list
      arg.validate(ctx)
      if !@fn.type.nest_list[k+1].cmp arg.type
        throw new Error "Fn_call validation error line=#{@line} pos=#{@pos}. arg[#{k}] type mismatch. Expected=#{@fn.type.nest_list[k+1]} found=#{arg.type}"
    return
  
  clone : ()->
    ret = new module.Fn_call
    ret.fn    = @fn.clone()
    for v in @arg_list
      ret.arg_list.push v.clone()
    ret.splat_fin = @splat_fin
    ret.type  = @type.clone() if @type
    ret.line  = @line
    ret.pos   = @pos
    ret

# ###################################################################################################
#    stmt
# ###################################################################################################
# TODO var_decl check
class @Scope
  list  : []
  need_nest : true
  line  : 0
  pos   : 0
  constructor:()->
    @list = []
  
  validate : (ctx = new module.Validation_context)->
    if @need_nest
      ctx_nest = ctx.mk_nest(true)
    else
      ctx_nest = ctx
    
    for stmt in @list # for Class_decl
      stmt.register?(ctx_nest)
    
    for stmt in @list
      stmt.validate(ctx_nest)
      # на самом деле валидными есть только Fn_call и assign, но мы об этом умолчим
    return
  
  clone : ()->
    ret = new module.Scope
    for v in @list
      ret.list.push v.clone()
    ret.need_nest = @need_nest
    ret.line  = @line
    ret.pos   = @pos
    ret

class @If
  cond: null
  t   : null
  f   : null
  line  : 0
  pos   : 0
  constructor:()->
    @t = new module.Scope
    @f = new module.Scope
  
  validate : (ctx = new module.Validation_context)->
    if !@cond
      throw new Error "If validation error line=#{@line} pos=#{@pos}. cond missing"
    
    @cond.validate(ctx)
    
    unless @cond.type.main in ["bool", "int"]
      throw new Error "If validation error line=#{@line} pos=#{@pos}. cond must be bool or int but found '#{@cond.type}'"
    
    @t.validate(ctx)
    @f.validate(ctx)
    
    if @t.list.length == 0
      perr "Warning. If empty true body"
    
    if @t.list.length == 0 and @f.list.length == 0
      throw new Error "If validation error line=#{@line} pos=#{@pos}. Empty true and false sections"
    return
  
  clone : ()->
    ret = new module.If
    ret.cond  = @cond.clone()
    ret.t     = @t.clone()
    ret.f     = @f.clone()
    ret.line  = @line
    ret.pos   = @pos
    ret

# есть следующие валидные случаи компилирования switch
# 1. cont типа int. Тогда все hash key трактуются как int. (Но нельзя NaN и Infinity)
# 2. cont типа float.
# 3. cont типа string.
# 4. cont типа char.

class @Switch
  cond  : null
  hash  : {}
  f     : null # scope
  line  : 0
  pos   : 0
  constructor:()->
    @hash = {}
    @f = new module.Scope
  
  validate : (ctx = new module.Validation_context)->
    if !@cond
      throw new Error "Switch validation error line=#{@line} pos=#{@pos}. cond missing"
    @cond.validate(ctx)
    
    if 0 == h_count @hash
      throw new Error "Switch validation error line=#{@line} pos=#{@pos}. no when conditions found"
    switch @cond.type.main
      when "int"
        for k,v of @hash
          if parseInt(k).toString() != k or !isFinite k
            throw new Error "Switch validation error line=#{@line} pos=#{@pos}. key '#{k}' can't be int"
      
      # when "float" # не разрешаем switch по  float т.к. нельзя сравнивать float'ы через ==
        # for k,v of @hash
          # if !isFinite k
            # throw new Error "Switch validation error line=#{@line} pos=#{@pos}. key '#{k}' can't be float"
      
      when "string"
        "nothing"
      
      else
        throw new Error "Switch validation error line=#{@line} pos=#{@pos}. Can't implement switch for condition type '#{@cond.type}'"
    
    for k,v of @hash
      v.validate(ctx.mk_nest())
    
    @f?.validate(ctx)
    
    return
  
  clone : ()->
    ret = new module.Switch
    ret.cond  = @cond.clone()
    for k,v of @hash
      ret.hash[k] = v.clone()
    ret.f     = @f.clone()
    ret.line  = @line
    ret.pos   = @pos
    ret
  
class @Loop
  scope : null
  line  : 0
  pos   : 0
  constructor:()->
    @scope = new module.Scope
  
  validate : (ctx = new module.Validation_context)->
    ctx_nest = ctx.mk_nest()
    ctx_nest.breakable = true
    @scope.validate(ctx_nest)
    
    found = false
    walk = (t)->
      switch t.constructor.name
        when "Scope"
          for v in t.list
            walk v
        
        when "If"
          walk t.t
          walk t.f
        
        when "Break", "Ret"
          found = true
      
      return
    
    walk @scope
    if !found
      throw new Error "Loop validation error line=#{@line} pos=#{@pos}. Break or Ret not found"
    # Не нужен т.к. все-равно ищем break
    # if @scope.list.length == 0
      # throw new Error "Loop validation error line=#{@line} pos=#{@pos}. Loop while is not allowed"
    return
  
  clone : ()->
    ret = new module.Loop
    ret.scope = @scope.clone()
    ret.line  = @line
    ret.pos   = @pos
    ret
  
class @Break
  line  : 0
  pos   : 0
  constructor:()->
  
  validate : (ctx = new module.Validation_context)->
    if !ctx.breakable
      throw new Error "Break validation error line=#{@line} pos=#{@pos}. You can't use break outside loop, while"
    
    return
  
  clone : ()->
    ret = new module.Break
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Continue
  line  : 0
  pos   : 0
  constructor:()->
  
  validate : (ctx = new module.Validation_context)->
    if !ctx.breakable
      throw new Error "Continue validation error line=#{@line} pos=#{@pos}. You can't use continue outside loop, while"
    
    return
  
  clone : ()->
    ret = new module.Continue
    ret.line  = @line
    ret.pos   = @pos
    ret

class @While
  cond  : null
  scope : null
  line  : 0
  pos   : 0
  constructor:()->
    @scope = new module.Scope
  
  validate : (ctx = new module.Validation_context)->
    if !@cond
      throw new Error "While validation error line=#{@line} pos=#{@pos}. cond missing"
    
    @cond.validate(ctx)
    unless @cond.type.main in ["bool", "int"]
      throw new Error "While validation error line=#{@line} pos=#{@pos}. cond must be bool or int"
    
    ctx_nest = ctx.mk_nest()
    ctx_nest.breakable = true
    @scope.validate(ctx_nest)
    
    if @scope.list.length == 0
      throw new Error "While validation error line=#{@line} pos=#{@pos}. Empty while is not allowed"
    return
  
  clone : ()->
    ret = new module.While
    ret.cond  = @cond.clone()
    ret.scope = @scope.clone()
    ret.line  = @line
    ret.pos   = @pos
    ret

class @For_range
  exclusive : true
  i     : null
  a     : null
  b     : null
  step  : null
  scope : null
  line  : 0
  pos   : 0
  constructor:()->
    @scope = new module.Scope
  
  validate : (ctx = new module.Validation_context)->
    if !@i
      throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Iterator is missing"
    if !@a
      throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Range a is missing"
    if !@b
      throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Range b is missing"
    
    @i.validate ctx
    @a.validate ctx
    @b.validate ctx
    @step?.validate ctx
    
    unless @i.type.main in ["int", "float"]
      throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Iterator should be type int or float but '#{@i.type}' found"
    unless @a.type.main in ["int", "float"]
      throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Range a should be type int or float but '#{@a.type}' found"
    unless @b.type.main in ["int", "float"]
      throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Range b should be type int or float but '#{@b.type}' found"
    if @step
      unless @step.type.main in ["int", "float"]
        throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Step should be type int or float but '#{@step.type}' found"
    
    if @i.type.main == "int"
      unless @a.type.main == "int"
        throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Range a should be type int because iterator is int but '#{@a.type}' found"
      unless @b.type.main == "int"
        throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Range b should be type int because iterator is int but '#{@b.type}' found"
      
      if @step
        unless @step.type.main == "int"
          throw new Error "For_range validation error line=#{@line} pos=#{@pos}. Step should be type int because iterator is int but '#{@step.type}' found"
    
    ctx_nest = ctx.mk_nest()
    ctx_nest.breakable = true
    @scope.validate ctx_nest
    return
  
  clone : ()->
    ret = new module.For_range
    ret.exclusive = @exclusive
    ret.i     = @i.clone()
    ret.a     = @a.clone()
    ret.b     = @b.clone()
    ret.step  = @step.clone() if @step
    ret.scope = @scope.clone()
    ret.line  = @line
    ret.pos   = @pos
    ret

class @For_col
  k : null
  v : null
  t : null
  scope : null
  line  : 0
  pos   : 0
  constructor:()->
    @scope = new module.Scope
  
  validate : (ctx = new module.Validation_context)->
    if !@t
      throw new Error "For_col validation error line=#{@line} pos=#{@pos}. Target is missing"
    if !@k and !@v
      throw new Error "For_col validation error line=#{@line} pos=#{@pos}. Key and value is missing"
    
    @t.validate ctx
    @k?.validate ctx
    @v?.validate ctx
    
    switch @t.type.main
      when "array", "hash_int"
        if @k
          unless @k.type.main == "int"
            throw new Error "For_col validation error line=#{@line} pos=#{@pos}. Key must be int for array<t> target but found '#{@k.type}'"
      
      when "hash"
        if @k
          unless @k.type.main == "string"
            throw new Error "For_col validation error line=#{@line} pos=#{@pos}. Key must be string for hash<t> target but found '#{@k.type}'"
      
      else
        throw new Error "For_col validation error line=#{@line} pos=#{@pos}. For_col accepts types array<t>, hash<t> and hash_int<t> but found '#{@t.type}'"
      
    if @v
      unless @v.type.cmp @t.type.nest_list[0]
        throw new Error "For_col validation error line=#{@line} pos=#{@pos}. Value must be '#{@t.type.nest_list[0]}' but found '#{@v.type}'"
    
    ctx_nest = ctx.mk_nest()
    ctx_nest.breakable = true
    @scope.validate ctx_nest
    return
  
  clone : ()->
    ret = new module.For_col
    ret.t     = @t.clone()
    ret.v     = @v.clone() if @v
    ret.k     = @k.clone() if @k
    ret.scope = @scope.clone()
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Ret
  t : null
  line  : 0
  pos   : 0
  validate : (ctx = new module.Validation_context)->
    @t?.validate(ctx)
    if !ctx.returnable
      throw new Error "Ret validation error line=#{@line} pos=#{@pos}. ctx must be returnable"
    
    return_type = ctx.check_id "$_return_type"
    if @t?
      if !@t.type.cmp return_type
        throw new Error "Ret validation error line=#{@line} pos=#{@pos}. Ret type must be '#{return_type}' but found '#{@t.type}'"
    else
      if return_type.main != "void"
        throw new Error "Ret validation error line=#{@line} pos=#{@pos}. Ret type must be '#{return_type}' but found void (no return value)"
    
    
    return
  
  clone : ()->
    ret = new module.Ret
    ret.t     = @t.clone() if @t
    ret.line  = @line
    ret.pos   = @pos
    ret
# ###################################################################################################
#    Exceptions
# ###################################################################################################
class @Try
  t : null
  c : null
  exception_var_name : ""
  line  : 0
  pos   : 0
  constructor : ()->
    @t = new module.Scope
    @c = new module.Scope
  
  # TODO validate
  
  clone : ()->
    ret = new module.Try
    ret.t     = @t.clone()
    ret.c     = @c.clone()
    ret.exception_var_name  = @exception_var_name
    ret.line  = @line
    ret.pos   = @pos
    ret
  
class @Throw
  t     : null
  line  : 0
  pos   : 0
  # TODO validate
  
  clone : ()->
    ret = new module.Throw
    ret.t     = @t.clone() if @t
    ret.line  = @line
    ret.pos   = @pos
    ret
  
# ###################################################################################################
#    decl
# ###################################################################################################
class @Var_decl
  name  : ""
  type  : null
  size  : null
  assign_value      : null
  assign_value_list : null
  line  : 0
  pos   : 0
  
  validate : (ctx = new module.Validation_context)->
    type_validate @type, ctx
    if ctx.check_id_decl(@name)
      throw new Error "Var_decl validation error line=#{@line} pos=#{@pos}. Redeclare '#{@name}'"
    
    # TODO size check
    # а еще с type связь скорее всего должна быть
    
    # TODO assign_value
    # TODO assign_value_list
    
    ctx.var_hash[@name] = @
    return
  
  clone : ()->
    ret = new module.Var_decl
    ret.name  = @name
    ret.type  = @type.clone() if @type
    ret.size  = @size
    ret.assign_value  = @assign_value.clone() if @assign_value
    if @assign_value_list
      ret.assign_value_list = []
      for v in @assign_value_list
        ret.assign_value_list.push v.clone()
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Class_decl
  name  : ""
  scope : null
  _prepared_field2type : {}
  line  : 0
  pos   : 0
  constructor:()->
    @scope = new module.Scope
    @_prepared_field2type = {}
  
  register : (ctx = new module.Validation_context)->
    if ctx.check_type @name
      throw new Error "Already registered '#{@name}'"
    ctx.type_hash[@name] = @
    return
  
  validate : (ctx = new module.Validation_context)->
    if !@name
      throw new Error "Class_decl validation error line=#{@line} pos=#{@pos}. Class should have name"
    
    @_prepared_field2type = {} # ensure reset (some generators rewrite this field)
    for v in @scope.list
      unless v.constructor.name in ["Var_decl", "Fn_decl"]
        throw new Error "Class_decl validation error line=#{@line} pos=#{@pos}. Only Var_decl and Fn_decl allowed at Class_decl, but '#{v.constructor.name}' found"
      @_prepared_field2type[v.name] = v.type
    
    ctx_nest = ctx.mk_nest()
    # wrapper
    var_decl = new module.Var_decl
    var_decl.name = "this"
    var_decl.type = new Type @name
    ctx_nest.var_hash["this"] = var_decl
    @scope.validate(ctx_nest)
    return
  
  clone : ()->
    ret = new module.Class_decl
    ret.name  = @name
    ret.scope = @scope.clone()
    for k,v of @_prepared_field2type
      ret._prepared_field2type[k] = v.clone()
    
    ret.line  = @line
    ret.pos   = @pos
    ret

class @Fn_decl
  is_closure : false
  name : ""
  type  : null
  arg_name_list  : []
  scope : null
  line  : 0
  pos   : 0
  constructor:()->
    @arg_name_list = []
    @scope = new module.Scope
  
  validate : (ctx = new module.Validation_context)->
    if !@name and !@is_closure
      throw new Error "Fn_decl validation error line=#{@line} pos=#{@pos}. Function should have name"
    
    type_validate @type, ctx
    if @type.main != "function"
      throw new Error "Fn_decl validation error line=#{@line} pos=#{@pos}. Type must be function but '#{@type}' found"
    if @type.nest_list.length-1 != @arg_name_list.length
      throw new Error "Fn_decl validation error line=#{@line} pos=#{@pos}. @type.nest_list.length-1 != @arg_name_list #{@type.nest_list.length-1} != #{@arg_name_list.length}"
    
    if @is_closure
      ctx_nest = ctx.mk_nest()
    else
      ctx_nest = ctx.seek_non_executable_parent().mk_nest()
    ctx_nest.executable = true
    ctx_nest.returnable = true
    
    for name,k in @arg_name_list
      decl = new module.Var_decl
      decl.name = name
      decl.type = @type.nest_list[1+k]
      ctx_nest.var_hash[name] = decl
    
    ctx_nest.var_hash["$_return_type"] = @type.nest_list[0]
    
    @scope.validate(ctx_nest)
    
    var_decl = new module.Var_decl
    var_decl.name = @name
    var_decl.type = @type
    ctx.var_hash[@name] = var_decl
    return
  
  clone : ()->
    ret = new module.Fn_decl
    ret.is_closure  = @is_closure
    ret.name  = @name
    ret.type  = @type.clone() if @type
    ret.arg_name_list = @arg_name_list.clone()
    ret.scope = @scope.clone()
    ret.line  = @line
    ret.pos   = @pos
    ret
  

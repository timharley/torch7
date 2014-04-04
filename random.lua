local wrap = require 'cwrap'

require 'torchcwrap'

local interface = wrap.CInterface.new()

interface:print(
   [[
#include "luaT.h"
#include "TH.h"

extern void torch_Generator_init(lua_State *L);
extern void torch_Generator_new(lua_State *L);
   ]])

for _,name in ipairs({"seed", "initialSeed"}) do
   interface:wrap(name,
                  string.format("THRandom_%s",name),
                  {{name='Generator', default=true},
                   {name="long", creturned=true}})
end

interface:wrap('manualSeed',
               'THRandom_manualSeed',
               {{name='Generator', default=true},
                {name="long"}})

interface:wrap('getRNGState',
                'THLongTensor_getRNGState',
                {{name='Generator', default=true},
                 {name='LongTensor',default=true,returned=true,method={default='nil'}}
                 })

interface:wrap('setRNGState',
                'THLongTensor_setRNGState',
                {{name='Generator', default=true},
                 {name='LongTensor',default=true,returned=true,method={default='nil'}}
                 })

interface:wrap('fastrandom',
                'THRandom_random',
                {{name='Generator', default=true},
                 {name='long', creturned=true},
                 })

interface:register("random__")
                
interface:print(
   [[
int randominteger(lua_State *L)
{
  int narg = lua_gettop(L);
  THGenerator * gen = NULL;
  long number;
  if(narg == 0)
  {
    lua_pushvalue(L, lua_upvalueindex(1));
  }
  gen = luaT_toudata(L, 1, torch_Generator);

  if(!gen)
  {
    luaL_error(L, "torch.randominteger(...) expected arguments: [Generator]");
  }

  number = THRandom_random(gen);
  lua_pushnumber(L, (lua_Number)number);
  return 1;
}

void torch_random_init(lua_State *L)
{
  torch_Generator_init(L);
  torch_Generator_new(L);
  lua_pushvalue(L, -1);
  lua_setfield(L, -3, "_gen");
  lua_pushcclosure(L, &randominteger, 1);
  lua_setfield(L, -2, "randominteger");
  luaL_register(L, NULL, random__);
}
]])

interface:tofile(arg[1])

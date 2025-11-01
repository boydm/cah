//
//  Created by Boyd Multerer on 2025-11-01.
//  Copyright © 2025 Boyd Multerer. All rights reserved.
//


#include <stdbool.h>
#include <math.h>
#include <erl_nif.h>

#define INDEX(w,x,y) (w * y + x)

#define rot6l(n) (((n << 1) & 63) | ((n & 32) >> 5))
#define rot6r(n) (n >> 1) | ((n & 1) << 5)
#define spin(n) rot6r(rot6r(rot6r(n)))

// its a matrix - the diagonal is the symmetry line
#define RULES { \
  0, 8, 16, 24, 32, 40, 48, 56, \
  1, 9, 17, 25, 33, 41, 49, 57, \
  2, 10, 18, 26, 34, 42, 50, 58, \
  3, 11, 19, 27, 35, 43, 51, 59, \
  4, 12, 20, 28, 36, 44, 52, 60, \
  5, 13, 21, 29, 37, 45, 53, 61, \
  6, 12, 22, 30, 38, 46, 54, 62, \
  7, 15, 23, 31, 39, 47, 55, 63 \
}
uint g_rules[] = RULES;

#define BITS { \
  0, 1, 1, 2, 1, 2, 2, 3, \
  1, 2, 2, 3, 2, 3, 3, 4, \
  1, 2, 2, 3, 2, 3, 3, 4, \
  2, 3, 3, 4, 3, 4, 4, 5, \
  1, 2, 2, 3, 2, 3, 3, 4, \
  2, 3, 3, 4, 3, 4, 4, 5, \
  2, 3, 3, 4, 3, 4, 4, 5, \
  3, 4, 4, 5, 4, 5, 5, 6 \
}
uint g_bits[] = BITS;

// #define COLORS { 0, 42, 84, 126, 168, 210 }
#define COLORS { 0, 200, 200, 200, 200, 200 }
uint g_colors[] = COLORS;

uint count = 0;

//=============================================================================
// utilities

//---------------------------------------------------------
// rotate 6 bits worth of n in a "random" direction
uint rand_rot6( uint n ) {
  if ( 1 && count++ ) {
    return rot6l(n);
  } else {
    return rot6r(n);
  }
}

//---------------------------------------------------------
// add a 1 to an empty cell in a "random" location
uint do_empty() {
  return 1 << (count++ % 6);
}

//---------------------------------------------------------
// remove a 1 from a full cell in a "random" location
uint do_full() {
  return 63 & ~(1 << (count++ % 6));
}

// //---------------------------------------------------------
// // get a value, accounting for wrapping
// uint get_wrap( ErlNifBinary  bin, uint width, uint x, uint y) {
//   uint max_x = width - 1;
//   uint max_y = (bin.size / width) - 1;
//   if (x < 0) {x = max_x;}
//   if (x > max_x) {x = 0;}
//   if (y < 0) {y = max_y;}
//   if (y > max_y) {y = 0;}
//   return bin.data[INDEX(width,x,y)];
// }

//---------------------------------------------------------
// get a value, accounting for wrapping
uint pos( uint width, uint height, uint x, uint y) {
  uint max_x = width - 1;
  uint max_y = height - 1;
  uint ny, nx = height - 1;

  if ( x < 0 ) {nx = max_x;}
  else if (x > max_x) {nx = 0;}
  else {nx = x;}

  if ( y < 0 ) {ny = max_y;}
  else if (y > max_y) {ny = 0;}
  else {ny = y;}

  // printf("x %d:%d. y %d:%d\n", x, nx, y, ny);

  return INDEX(width,nx,ny);
}


//=============================================================================
// Erlang NIF stuff from here down.

static ERL_NIF_TERM
nif_empty(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  return enif_make_uint( env, do_empty() ); 
}

static ERL_NIF_TERM
nif_full(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  return enif_make_uint( env, do_full() ); 
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_rot6l(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  unsigned int  n;

  if ( !enif_get_uint(env, argv[0], &n) )           {return enif_make_badarg(env);}

  return enif_make_uint( env, rot6l(n) ); 
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_rot6r(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  unsigned int  n;

  if ( !enif_get_uint(env, argv[0], &n) )           {return enif_make_badarg(env);}

  return enif_make_uint( env, rot6r(n) ); 
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_get(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  bin;
  unsigned int  w;
  unsigned int  x;
  unsigned int  y;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &bin) )   {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &w) )           {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &x) )           {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &y) )           {return enif_make_badarg(env);}

  // bounds checking is in the elixir module
  return enif_make_uint( env, bin.data[INDEX(w,x,y)] ); 
}

//-----------------------------------------------------------------------------
static ERL_NIF_TERM
nif_put(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  bin;
  unsigned int  w;
  unsigned int  x;
  unsigned int  y;
  unsigned int  v;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &bin) )   {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &w) )           {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &x) )           {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &y) )           {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[4], &v) )           {return enif_make_badarg(env);}

  // bounds checking is in the elixir module
  bin.data[INDEX(w,x,y)] = v;
  return argv[0]; 
}

static ERL_NIF_TERM
nif_step(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  bin, bout;
  unsigned int  width;
  unsigned int  height;
  unsigned int  i;
  unsigned int  n, b;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &bin) )   {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[1], &width) )       {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &height) )      {return enif_make_badarg(env);}
  if ( !enif_inspect_binary(env, argv[3], &bout) )  {return enif_make_badarg(env);}

  // transform the incoming array by the rules
  for ( uint y = 0; y < height; y++) {
    for ( uint x = 0; x < width; x++) {
      i = INDEX(width,x,y);
      n = bin.data[i];
      switch (n) {
        case 9:
        case 18:
        case 27:
        case 36:
        case 45:
        case 54:
          // bin.data[i] = n;
          // bin.data[i] = rand_rot6(n);
          break;
        case 0:
          // b = 0;
          // bin.data[i] = do_empty();
          break;
        case 63:
          // b = 63;
          // bin.data[i] = do_full();
          break;
        // default:
          // bin.data[i] = rules[n];
      }
    }
  }

  // build the outgoing array by the transformed input
  for ( uint y = 0; y < height; y++) {
    for ( uint x = 0; x < width; x++) {
      // i = INDEX(width,x,y);
      n = 0;
      n |= bin.data[pos(width, height, x - 1, y - 1)] & 1;
      n |= bin.data[pos(width, height, x , y - 1)] & 2;
      n |= bin.data[pos(width, height, x + 1, y )] & 4;
      n |= bin.data[pos(width, height, x , y + 1 )] & 8;
      n |= bin.data[pos(width, height, x - 1, y + 1)] & 16;
      n |= bin.data[pos(width, height, x - 1 , y)] & 32;
      bout.data[INDEX(width,x,y)] = n;
    }
  }

  return argv[3];
}


static ERL_NIF_TERM
nif_render(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary  pix, ca;
  unsigned int  width;
  unsigned int  height;
  uint i, c;

  // get the parameters
  if ( !enif_inspect_binary(env, argv[0], &pix) )   {return enif_make_badarg(env);}
  if ( !enif_inspect_binary(env, argv[1], &ca) )   {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[2], &width) )       {return enif_make_badarg(env);}
  if ( !enif_get_uint(env, argv[3], &height) )      {return enif_make_badarg(env);}

  // render out
  for ( uint y = 0; y < height; y++) {
    for ( uint x = 0; x < width; x++) {
      i = INDEX(width,x,y);
      c = ca.data[i];
      c = g_bits[c];
      c = g_colors[c];
      pix.data[i] = c;
    }
  }

  return argv[0];
}


//=============================================================================
// erl housekeeping. This is the list of functions available to the erl side

static ErlNifFunc nif_funcs[] = {
  {"nif_rot6l",  1, nif_rot6l,  0},
  {"nif_rot6r",  1, nif_rot6r,  0},
  {"nif_empty",  0, nif_empty,  0},
  {"nif_full",  0, nif_full,  0},

  {"nif_get",   4, nif_get,   0},
  {"nif_put",   5, nif_put,   0},
  {"nif_step",  4, nif_step,  0},

  {"nif_render",  4, nif_render,  0}
};

ERL_NIF_INIT(Elixir.Cah.Ca.Hex, nif_funcs, NULL, NULL, NULL, NULL)

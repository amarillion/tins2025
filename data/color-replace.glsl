#ifdef GL_ES
precision lowp float;
#endif
uniform sampler2D al_tex;
uniform bool al_use_tex;
uniform bool al_alpha_test;
uniform int al_alpha_func;
uniform float al_alpha_test_val;
varying vec4 varying_color;
varying vec2 varying_texcoord;

uniform vec3 red_replacement;
uniform vec3 green_replacement;

bool alpha_test_func(float x, int op, float compare);

void main()
{
  vec4 c;
  if (al_use_tex)
    c = varying_color * texture2D(al_tex, varying_texcoord);
  else
    c = varying_color;
    
  if (!al_alpha_test || alpha_test_func(c.a, al_alpha_func, al_alpha_test_val)) {
    if (c.r > 0.5 && c.g == 0.0 && c.b == 0.0) {
      c = vec4(red_replacement.r * c.r, red_replacement.g * c.r, red_replacement.b * c.r, c.a);
    }
    if (c.r == 0.0 && c.g > 0.5 && c.b == 0.0) {
      c = vec4(green_replacement.r * c.g, green_replacement.g * c.g, green_replacement.b * c.g, c.a);
    }
    gl_FragColor = c;
  }
  else
    discard;
}

bool alpha_test_func(float x, int op, float compare)
{
  if (op == 0) return false;
  else if (op == 1) return true;
  else if (op == 2) return x < compare;
  else if (op == 3) return x == compare;
  else if (op == 4) return x <= compare;
  else if (op == 5) return x > compare;
  else if (op == 6) return x != compare;
  else if (op == 7) return x >= compare;
  return false;
}

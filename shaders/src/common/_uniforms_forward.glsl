// clang-format off

// https://github.com/sp614x/optifine/blob/master/OptiFineDoc/doc/shaders.txt

uniform sampler2D texture; // See: /src/modules/lab_pbr.glsl; TODO: gtexture?
uniform sampler2D lightmap;
uniform sampler2D normals; // See: /src/modules/lab_pbr.glsl
uniform sampler2D specular; // See: /src/modules/lab_pbr.glsl
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D depthtex0;
uniform sampler2D colortex4;  // <custom texture or output from deferred programs>
uniform sampler2D colortex5;  // <custom texture or output from deferred programs>
uniform sampler2D colortex6;  // <custom texture or output from deferred programs>
uniform sampler2D colortex7;  // <custom texture or output from deferred programs>
uniform sampler2D colortex8;  // <custom texture or output from deferred programs>
uniform sampler2D colortex9;  // <custom texture or output from deferred programs>
uniform sampler2D colortex10; // <custom texture or output from deferred programs>
uniform sampler2D colortex11; // <custom texture or output from deferred programs>
uniform sampler2D colortex12; // <custom texture or output from deferred programs>
uniform sampler2D colortex13; // <custom texture or output from deferred programs>
uniform sampler2D colortex14; // <custom texture or output from deferred programs>
uniform sampler2D colortex15; // <custom texture or output from deferred programs>
uniform sampler2D depthtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D noisetex;

// clang-format on

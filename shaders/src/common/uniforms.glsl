uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

uniform int   heldItemId;
uniform int   heldItemId2;
uniform float fogStart;
uniform float fogEnd;
uniform int   worldTime;
uniform int   frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform vec3  sunPosition; 
uniform vec3  moonPosition; 
uniform vec3  shadowLightPosition;
uniform vec3  upPosition;
uniform vec3  cameraPosition;
uniform vec3  previousCameraPosition;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int   isEyeInWater;
uniform vec4  entityColor;
uniform float near;
uniform float far;

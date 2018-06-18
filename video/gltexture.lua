local M = {}

local ffi = require "ffi"
local gles2 = require "video.egl"
local gles2 = require "video.gles2"
--local bs = require "baresip"

ffi.cdef[[
	struct vidisp_st {
		//const struct vidisp* vd;
		struct pthread_mutex_t* mutex;
		EGLDisplay* display;
		EGLSurface* surface;
		EGLContext* context;
		int program;
	};
]]

local VProgram = [[
	attribute vec2 position;
	attribute vec2 texcoord_in;
	varying vec2 texcoord;
	void main()
	{                            
	   texcoord = texcoord_in;          
	   gl_Position = vec4(position, 0.0, 1.0); 
	}
]]

local FProgram = [[
uniform sampler2D Ytex;
uniform sampler2D Utex,Vtex;
varying lowp vec2 texcoord;
void main(void) {
	lowp float r,g,b,y,u,v;
	y=texture2D(Ytex,texcoord).r;
	u=texture2D(Utex,texcoord).r;
	v=texture2D(Vtex,texcoord).r;
	y=1.1643*(y-0.0625);
	u=u-0.5;
	v=v-0.5;

	r=y+1.5958*v;
	g=y-0.39173*u-0.81290*v;\
	b=y+2.017*u;

	gl_FragColor=vec4(r,g,b,1.0);
}
]]


function M.init_shaders()
	progv = ffi.new("const char* [1]", {VProgram})
	local buf = ffi.new("char[1024]", {})
	local i = ffi.new("int[1]")

	gles2.clearColor(0, 0, 0.0, 0)
	
	-- Set up program objects.
	local PHandle = gles2.createProgram();
	local VSHandle = gles2.createShader(gles2.VERTEX_SHADER);
	local FSHandle = gles2.createShader(gles2.FRAGMENT_SHADER);

	gles2.checkError("Shader Objects")
	
	-- Compile the shader.

	progv = ffi.new("const char* [1]", {VProgram})
	gles2.shaderSource(VSHandle, 1, progv, nil);
	gles2.checkError("Shader Source")
	gles2.compileShader(VSHandle);
	gles2.checkError("Shader Compile")
	-- Print the compilation log.
	gles2.getShaderiv(VSHandle, gles2.COMPILE_STATUS, i);
	gles2.checkError("Shader get COMPILE_STATUS")
	if i[0] ~= 1 then
		gles2.getShaderInfoLog(FSHandle, ffi.sizeof(buf), nil, buf);
		--warning("opengl: vertex shader compile failed\n%s\n", buf);
		print("opengl: vertex shader compile failed\n", ffi.string(buf));
		return
		--return ENOSYS;
	end
	
	progv[0] = FProgram;
	gles2.shaderSource(FSHandle, 1, progv, nil);
	gles2.compileShader(FSHandle);
	
	-- Print the compilation log. 
	gles2.getShaderiv(FSHandle, gles2.COMPILE_STATUS, i);
	if i[0] ~= 1 then
		gles2.getShaderInfoLog(FSHandle, ffi.sizeof(buf), NULL, buf);
		--warning("opengl: fragment shader compile failed\n%s\n", buf);
		print("opengl: fragment shader compile failed\n", ffi.string(buf));
		--return ENOSYS;
		return
	end

	-- Create a complete program object.
	gles2.attachShader(PHandle, VSHandle);
	gles2.attachShader(PHandle, FSHandle);
	gles2.checkError("Fragment Shader Attach")
	gles2.linkProgram(PHandle);

	-- And print the link log.
	gles2.getProgramInfoLog(PHandle, ffi.sizeof(buf), nil, buf);
	print ("PHandle", PHandle, "isProgram", gles2.isProgram(PHandle))
	-- Finally, use the program.
	gles2.useProgram(PHandle);
	--gles2.checkError("Use Program")

	return PHandle
end

function M.upload_yuv(program, height, Ytex, Utex, Vtex, widthY, widthU, widthV)
	-- Select texture unit 1 as the active unit and bind the U texture.
	gles2.activeTexture(gles2.TEXTURE1)
	--gles2.checkError("activate texture")
	local i = gles2.getUniformLocation(program, "Utex");
	gles2.uniform1i(i,1);  -- Bind Utex to texture unit 1 --
	gles2.bindTexture(gles2.TEXTURE_2D,1);
	
	gles2.texParameteri(gles2.TEXTURE_2D,
			gles2.TEXTURE_MAG_FILTER, gles2.LINEAR)
	gles2.texParameteri(gles2.TEXTURE_2D,
			gles2.TEXTURE_MIN_FILTER, gles2.LINEAR)
	gles2.texImage2D(gles2.TEXTURE_2D, 0, gles2.LUMINANCE,
		widthU, height/2, 0,
		gles2.LUMINANCE, gles2.UNSIGNED_BYTE, Utex)

	--gles2.checkError("upload texture U")

	-- Select texture unit 2 as the active unit and bind the V texture. 
	gles2.activeTexture(gles2.TEXTURE2)
	i = gles2.getUniformLocation(program, "Vtex")
	gles2.bindTexture(gles2.TEXTURE_2D, 2)
	gles2.uniform1i(i, 2) -- Bind Vtext to texture unit 2

	gles2.texParameteri(gles2.TEXTURE_2D,
			gles2.TEXTURE_MAG_FILTER, gles2.LINEAR)
	gles2.texParameteri(gles2.TEXTURE_2D,
			gles2.TEXTURE_MIN_FILTER, gles2.LINEAR);

	gles2.texImage2D(gles2.TEXTURE_2D, 0, gles2.LUMINANCE,
		widthV, height/2, 0,
		gles2.LUMINANCE, gles2.UNSIGNED_BYTE, Vtex)

	--gles2.checkError("upload texture V")

	-- Select texture unit 0 as the active unit and bind the Y texture.
	gles2.activeTexture(gles2.TEXTURE0);
	i = gles2.getUniformLocation(program, "Ytex")
	gles2.uniform1i(i,0) -- Bind Ytex to texture unit 0
	gles2.bindTexture(gles2.TEXTURE_2D, 3)

	gles2.texParameteri(gles2.TEXTURE_2D,
			gles2.TEXTURE_MAG_FILTER, gles2.LINEAR)
	gles2.texParameteri(gles2.TEXTURE_2D,
			gles2.TEXTURE_MIN_FILTER, gles2.LINEAR)

	gles2.texImage2D(gles2.TEXTURE_2D, 0, gles2.LUMINANCE,
			widthY, height, 0,
			gles2.LUMINANCE, gles2.UNSIGNED_BYTE, Ytex)
end	

function M.draw_blit(PHandle)
	gles2.clear(gles2.COLOR_BUFFER_BIT);
	gles2.useProgram(PHandle)

	local texcoords = ffi.new("float[8]", {
		0.0, 1.0,
		1.0, 1.0,
		0.0, 0.0,
		1.0, 0.0
	})

	local vertices = ffi.new("float[12]", {
		-1, -1, -- bottom left corner
		1, -1, -- top left corner
		-1, 1, -- top right corner
		1, 1, -- bottom right corner
	})
	-- Specify the layout of the vertex data
	local posAttrib = gles2.getAttribLocation(PHandle, "position");
	gles2.enableVertexAttribArray(posAttrib);
	gles2.vertexAttribPointer(posAttrib, 2, gles2.FLOAT, false, 0, vertices);

	local texAttrib = gles2.getAttribLocation(PHandle, "texcoord_in");
	gles2.enableVertexAttribArray(texAttrib);
	gles2.vertexAttribPointer(texAttrib, 2, gles2.FLOAT, false, 0, texcoords);
	    
	gles2.drawArrays(gles2.TRIANGLE_STRIP, 0, 4);
end


return M

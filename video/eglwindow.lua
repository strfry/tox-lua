local x11 = require "video.x11"
local egl = require "video.egl"

local M = {}
M.__index = M
M.egl = egl -- TODO: What's the correct way to keep refs around?

function M.egl_init(self, nativewindow)
	local ffi = require "ffi"
	local CONTEXT = ffi.new('int[3]', {egl.CONTEXT_CLIENT_VERSION, 2,
									 egl.NONE})
	local attrib = ffi.new('int[11]', {egl.RED_SIZE, 8,
	  egl.GREEN_SIZE, 8, egl.BLUE_SIZE, 8, egl.NONE})

	local numConfigs = ffi.new('int[1]')
	local config = ffi.new('void *[1]')
	local display = egl.getDisplay(ffi.cast("EGLDisplay",egl.DEFAULT_DISPLAY))
	assert(display, "eglGetDisplay failed.")

	local major = ffi.new("uint32_t[1]")
	local minor = ffi.new("uint32_t[1]")
	local res = egl.initialize(display, major, minor)
	assert(res ~= 0, "eglInitialize failed.")
	self.majorVersion = major[0]
	self.minorVersion = minor[0]

	res = egl.chooseConfig(display, attrib, config, 1, numConfigs)
	assert(res ~= 0, "eglChooseConfig failed.")
	local surface = egl.createWindowSurface(display, config[0],
				  ffi.cast("void*", nativewindow), nil)

	assert(surface, "eglCreateWindowSurface failed.")

	local context = egl.createContext(display, config[0], nil, CONTEXT)
	assert(context, "eglCreateContext failed.")

	res = egl.makeCurrent(display, surface, surface, context)
	assert(res ~= 0, "eglMakeCurrent failed.")

	self.context = context
	self.frames = 0
	self.display = display
	self.surface = surface
	return true
end

function M.bind_context(self)
	res = egl.makeCurrent(self.display, self.surface, self.surface, self.context)
	assert(res ~= 0, "eglMakeCurrent failed.")
end

function M.unbind_context(self)
	res = egl.makeCurrent(self.display, egl.EGL_NO_SURFACE, egl.EGL_NO_SURFACE, egl.EGL_NO_CONTEXT)
	assert(res ~= 0, "eglMakeCurrent failed.")
end

function M.update(self)
	if not self.window:update() then
		return false
	end
	egl.swapBuffers(self.display, self.surface)
	return true
end

function M.create(width, height)
	local self = setmetatable({}, M)
	self.window = x11.create_window(width, height)
	self:egl_init(self.window.x_window)
	return self
end

return M

local ffi = require "ffi"
local v4l2 = require "camera.headers"

lib = ffi.load("v4l2")

local function xioctl(fd, request, arg)
	local r
	repeat
		r = lib.v4l2_ioctl(fd, request, arg)
	until r ~= -1 or errno ~= lib.EINTR
	return r
end

M = {}

function M.print_video_input(self)
	local pinput = ffi.new("struct v4l2_input[1]")
	local pindex = ffi.new("uint32_t[1]")

	if -1 == lib.v4l2_ioctl(self.fd, v4l2.VIDIOC_G_INPUT, pindex) then
		error("v4l2: v4l2.VIDIOC_G_INPUT", ffi.errno())
	end

	if -1 == lib.v4l2_ioctl(self.fd, v4l2.VIDIOC_ENUMINPUT, pinput) then
		return ffi.C.perror "v4l2: v4l2.VIDIOC_ENUMINPUT"
	end

	print ("v4l2: Current input: ", ffi.string(pinput[0].name))
end

function M.print_framerate(self)
	local streamparm = ffi.new("struct v4l2_streamparm[1]")

	streamparm[0].type = lib.V4L2_BUF_TYPE_VIDEO_CAPTURE;

	if lib.v4l2_ioctl(self.fd, v4l2.VIDIOC_G_PARM, streamparm) ~= 0 then
		error("v4l2: v4l2.VIDIOC_G_PARM error", errno);
	end

	local tpf = streamparm[0].parm.capture.timeperframe;
	local fps = tpf.denominator / tpf.numerator;

	print(string.format("v4l2: current framerate is %.2f fps", fps));
end

function M.init_mmap(self, devname)
	local preq = ffi.new("struct v4l2_requestbuffers[1]")
	local req = preq[0]

	req.count  = 4
	req.type   = lib.V4L2_BUF_TYPE_VIDEO_CAPTURE
	req.memory = lib.V4L2_MEMORY_MMAP

	if -1 == xioctl(self.fd, v4l2.VIDIOC_REQBUFS, preq) then
		--if ffi.errno == ffi.EINVAL
		error("Device does not support memory mapping!")
	end

	if req.count < 2 then
		error("Insufficient buffer memory on v4l2 device")
	end

	self.buffers = {}
	for i=1,req.count do
		local pbuf = ffi.new("struct v4l2_buffer[1]")
		local buf = pbuf[0]

		buf.type = lib.V4L2_BUF_TYPE_VIDEO_CAPTURE
		buf.memory = lib.V4L2_MEMORY_MMAP
		buf.index  = i - 1

		if xioctl(self.fd, v4l2.VIDIOC_QUERYBUF, pbuf) == -1 then
			error("v4l2: v4l2.VIDIOC_QUERYBUF", ffi.errno())
		end

		local start = lib.v4l2_mmap(
			nil, -- /* start anywhere */,
			buf.length,
			bit.bor(lib.PROT_READ, lib.PROT_WRITE), -- /* required */,
			lib.MAP_SHARED, -- /* recommended */,
			self.fd, buf.m.offset
		)

		if start == -1 then
			error("v4l2: mmap failed", lib.ENODEV);
		end

		self.buffers[i] = {
			length = buf.length,
			start = ffi.cast("uint8_t*", start)
		}
	end
end

function M.init_device(self, devname, width, height)
	local pcap = ffi.new("struct v4l2_capability[1]")
	--struct v4l2_fmtdesc fmts;
	--unsigned int min;
	--const char *pix;
	--int err;

	if -1 == xioctl(self.fd, v4l2.VIDIOC_QUERYCAP, pcap) then
		error("v4l2: v4l2.VIDIOC_QUERYCAP: %m\n", ffi.errno());
	end

	local caps = pcap[0].capabilities

	if bit.band(caps, lib.V4L2_CAP_VIDEO_CAPTURE) == 0 then
		error("v4l2 device is not capture device!")
	end

	if bit.band(caps, lib.V4L2_CAP_STREAMING) == 0 then
		error("v4l2 device does not support streaming i/o!")
	end
	
	local pfmts = ffi.new("struct v4l2_fmtdesc[1]")
	pfmts[0].type = lib.V4L2_BUF_TYPE_VIDEO_CAPTURE

	pfmts[0].index = 0
	while 0 == lib.v4l2_ioctl(self.fd, v4l2.VIDIOC_ENUM_FMT, pfmts) do
		if pfmts[0].pixelformat == v4l2.V4L2_PIX_FMT_YUV420 then
			self.pixfmt = pfmts[0].pixelformat
		end
		pfmts[0].index = pfmts[0].index + 1
	end

	if self.pixfmt == nil then
		error("v4l2 format negotiation failed", ffi.errno())
	end

	local pfmt = ffi.new("struct v4l2_format[1]")
	local fmt = pfmt[0]

	fmt.type		= lib.V4L2_BUF_TYPE_VIDEO_CAPTURE
	fmt.fmt.pix.width       = width;
	fmt.fmt.pix.height      = height;
	fmt.fmt.pix.pixelformat = self.pixfmt;
	fmt.fmt.pix.field       = lib.V4L2_FIELD_INTERLACED;

	--error("foo")
	if xioctl(self.fd, v4l2.VIDIOC_S_FMT, pfmt) == -1 then
		error("v4l2: v4l2.VIDIOC_S_FMT: ", ffi.errno());
	end

	-- /* Note v4l2.VIDIOC_S_FMT may change width and height. */

	-- /* Buggy driver paranoia. */
	min = fmt.fmt.pix.width * 2;
	if fmt.fmt.pix.bytesperline < min then
		fmt.fmt.pix.bytesperline = min
	end
	min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
	if fmt.fmt.pix.sizeimage < min then
		fmt.fmt.pix.sizeimage = min
	end

	self.width = fmt.fmt.pix.width;
	self.height = fmt.fmt.pix.height;

	self:init_mmap(devname);

	-- TODO: REVERSE FOURCC
	local pix = fmt.fmt.pix.pixelformat

	if self.pixfmt ~= fmt.fmt.pix.pixelformat then
		error(string.format("v4l2: got unexpected pixel format: %s", pix))
	end

	print(string.format("v4l2: %s: found valid V4L2 device (%u x %u) pixfmt=%c%c%c%c\n",
	       dev_name, fmt.fmt.pix.width, fmt.fmt.pix.height,
			pix,
			bit.rshift(pix, 8),
			bit.rshift(pix, 16),
			bit.rshift(pix, 24)
	))
end

function M.stop_capturing(self)
	if self.fd >= 0 then
		local ptype = ffi.new("enum v4l2_buf_type[1]", lib.V4L2_BUF_TYPE_VIDEO_CAPTURE)
		xioctl(self.fd, v4l2.VIDIOC_STREAMOFF, ptype);
	end
end

function M.uninit_device(self)
	for i, buf in pairs(self.buffers) do
		lib.v4l2_munmap(buf.start, buf.length)
	end

	self.buffers = nil
end

function M.start_capturing(self)
	for i, _ in ipairs(self.buffers) do
		local pbuf = ffi.new("struct v4l2_buffer[1]")
		local buf = pbuf[0]
		buf.type = lib.V4L2_BUF_TYPE_VIDEO_CAPTURE
		buf.memory = lib.V4L2_MEMORY_MMAP
		buf.index = i - 1

		if xioctl(self.fd, v4l2.VIDIOC_QBUF, pbuf) == -1 then
			error("v4l2: v4l2.VIDIOC_QBUF", ffi.errno())
		end		
	end

	local ptype = ffi.new("int[1]", lib.V4L2_BUF_TYPE_VIDEO_CAPTURE)
	if xioctl(self.fd, v4l2.VIDIOC_STREAMON, ptype) == -1 then
		error("v4l2: v4l2.VIDIOC_STREAMON", ffi.errno())
	end
end

function M.read_frame(self)
	local buf = ffi.new("struct v4l2_buffer[1]")
	--struct timeval ts;
	--uint64_t timestamp;

	buf[0].type = lib.V4L2_BUF_TYPE_VIDEO_CAPTURE
	buf[0].memory = lib.V4L2_MEMORY_MMAP


	if -1 == xioctl(self.fd, v4l2.VIDIOC_DQBUF, buf) then
		if ffi.errno() == lib.EAGAIN then
			return nil
			
		--else if ffi.errno == EIO
		--	/* Could ignore EIO, see spec. */
		else
			error("spontaneous ioctl(fd, 0) error. run with jit.off()!")
			error("v4l2: v4l2.VIDIOC_DQBUF: %m\n", ffi.errno())
		end
	end
	
	--ts = buf.timestamp;
	--timestamp = 1000000U * ts.tv_sec + ts.tv_usec;
	--timestamp = timestamp * VIDEO_TIMEBASE / 1000000U;

	--call_frame_handler(st, st->buffers[buf.index].start, timestamp);

	if -1 == xioctl(self.fd, v4l2.VIDIOC_QBUF, buf) then
		--error("v4l2: v4l2.VIDIOC_QBUF\n", ffi.errno());
		print (string.format("error: could not requeue buffer %d", buf[0].index))
		return nil
	end

	local yuv = self.buffers[buf[0].index + 1]
	local yoff = self.width * self.height
	local uoff = yoff / 4
	return yuv.start, yuv.start + yoff, yuv.start + yoff + uoff
end



function M.__index(self, key)
	return M[key]
end

function M.open(width, height, device)
	self = {}
	self.buffers = {}
	setmetatable(self, M)
	
	if device == nil then
		viddev = '/dev/video0'
	end

	self.fd = lib.v4l2_open(viddev, lib.O_RDWR)
	if self.fd < 0 then
		error "could not open v4l2 device!"
	end

	self:print_video_input()
	self:print_framerate()

	self:init_device(device, width, height)

	self:start_capturing()

	return self
end

function M.close(self)
	self:stop_capturing();
	self:uninit_device();

	lib.v4l2_close(self.fd)
end

return M

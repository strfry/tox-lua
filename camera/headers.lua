local ffi = require "ffi"

--local preamble = [[
ffi.cdef[[
	typedef unsigned char __u8;
	typedef int __s32;
	typedef unsigned short __u16;
	typedef unsigned int __u32;
	typedef unsigned long long __u64;
	struct FILE;
	typedef struct FILE FILE;
]]

-- errno
ffi.cdef[[
enum {
	EINTR		= 4,
	EAGAIN		= 11,
	ENODEV		= 19,
};

enum {
	O_RDWR	= 0x2,
	
	MAP_SHARED = 0x1,
	
	PROT_READ = 0x1,
	PROT_WRITE = 0x2,
};
]]

-- Stuff copied from linux/videodev2.h
ffi.cdef[[
typedef __u64 v4l2_std_id;

struct v4l2_input {
        __u32        index;             /*  Which input */
        __u8         name[32];          /*  Label */
        __u32        type;              /*  Type of input */
        __u32        audioset;          /*  Associated audios (bitfield) */
        __u32        tuner;             /*  enum v4l2_tuner_type */
        v4l2_std_id  std;
        __u32        status;
        __u32        capabilities;
        __u32        reserved[3];
};

typedef long __kernel_time_t;
typedef long __kernel_suseconds_t;

struct timeval {
        __kernel_time_t         tv_sec;         /* seconds */
        __kernel_suseconds_t    tv_usec;        /* microseconds */
};

enum v4l2_memory {
	V4L2_MEMORY_MMAP             = 1,
	V4L2_MEMORY_USERPTR          = 2,
	V4L2_MEMORY_OVERLAY          = 3,
	V4L2_MEMORY_DMABUF           = 4,
};

enum v4l2_buf_type {
	V4L2_BUF_TYPE_VIDEO_CAPTURE        = 1,
	V4L2_BUF_TYPE_VIDEO_OUTPUT         = 2,
	V4L2_BUF_TYPE_VIDEO_OVERLAY        = 3,
	V4L2_BUF_TYPE_VBI_CAPTURE          = 4,
	V4L2_BUF_TYPE_VBI_OUTPUT           = 5,
	V4L2_BUF_TYPE_SLICED_VBI_CAPTURE   = 6,
	V4L2_BUF_TYPE_SLICED_VBI_OUTPUT    = 7,
	/* Experimental */
	V4L2_BUF_TYPE_VIDEO_OUTPUT_OVERLAY = 8,
	V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE = 9,
	V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE  = 10,
	V4L2_BUF_TYPE_SDR_CAPTURE          = 11,
	V4L2_BUF_TYPE_SDR_OUTPUT           = 12,
	/* Deprecated, do not use */
	V4L2_BUF_TYPE_PRIVATE              = 0x80,
};

enum v4l2_field {
	V4L2_FIELD_ANY           = 0, /* driver can choose from none,
					 top, bottom, interlaced
					 depending on whatever it thinks
					 is approximate ... */
	V4L2_FIELD_NONE          = 1, /* this device has no fields ... */
	V4L2_FIELD_TOP           = 2, /* top field only */
	V4L2_FIELD_BOTTOM        = 3, /* bottom field only */
	V4L2_FIELD_INTERLACED    = 4, /* both fields interlaced */
	V4L2_FIELD_SEQ_TB        = 5, /* both fields sequential into one
					 buffer, top-bottom order */
	V4L2_FIELD_SEQ_BT        = 6, /* same as above + bottom-top order */
	V4L2_FIELD_ALTERNATE     = 7, /* both fields alternating into
					 separate buffers */
	V4L2_FIELD_INTERLACED_TB = 8, /* both fields interlaced, top field
					 first and the top field is
					 transmitted first */
	V4L2_FIELD_INTERLACED_BT = 9, /* both fields interlaced, top field
					 first and the bottom field is
					 transmitted first */
};

struct v4l2_fmtdesc {
	__u32		    index;             /* Format number      */
	__u32		    type;              /* enum v4l2_buf_type */
	__u32               flags;
	__u8		    description[32];   /* Description string */
	__u32		    pixelformat;       /* Format fourcc      */
	__u32		    reserved[4];
};

struct v4l2_timecode {
	__u32	type;
	__u32	flags;
	__u8	frames;
	__u8	seconds;
	__u8	minutes;
	__u8	hours;
	__u8	userbits[4];
};

struct v4l2_buffer {
	__u32			index;
	__u32			type;
	__u32			bytesused;
	__u32			flags;
	__u32			field;
	struct timeval		timestamp;
	struct v4l2_timecode	timecode;
	__u32			sequence;

	/* memory location */
	__u32			memory;
	union {
		__u32           offset;
		unsigned long   userptr;
		struct v4l2_plane *planes;
		__s32		fd;
	} m;
	__u32			length;
	__u32			reserved2;
	__u32			reserved;
};


// Custom re-declaration as enum
enum v4l2_capabilities_defines {
	V4L2_CAP_VIDEO_CAPTURE        = 0x00000001,  /* Is a video capture device */
	V4L2_CAP_VIDEO_OUTPUT         = 0x00000002,  /* Is a video output device */
	V4L2_CAP_VIDEO_OVERLAY        = 0x00000004,  /* Can do video overlay */
	V4L2_CAP_VBI_CAPTURE          = 0x00000010,  /* Is a raw VBI capture device */
	V4L2_CAP_VBI_OUTPUT           = 0x00000020,  /* Is a raw VBI output device */
	V4L2_CAP_SLICED_VBI_CAPTURE   = 0x00000040,  /* Is a sliced VBI capture device */
	V4L2_CAP_SLICED_VBI_OUTPUT    = 0x00000080,  /* Is a sliced VBI output device */
	V4L2_CAP_VIDEO_OUTPUT_OVERLAY = 0x00000200,  /* Can do video output overlay */
	V4L2_CAP_STREAMING            = 0x04000000  /* streaming I/O ioctls */
};

struct v4l2_capability {
	__u8	driver[16];
	__u8	card[32];
	__u8	bus_info[32];
	__u32   version;
	__u32	capabilities;
	__u32	device_caps;
	__u32	reserved[3];
};

enum {
	VIDEO_MAX_PLANES             = 8,
};

struct v4l2_plane_pix_format {
	__u32		sizeimage;
	__u32		bytesperline;
	__u16		reserved[6];
} __attribute__ ((packed));

struct v4l2_pix_format {
	__u32         		width;
	__u32			height;
	__u32			pixelformat;
	__u32			field;		/* enum v4l2_field */
	__u32            	bytesperline;	/* for padding, zero if unused */
	__u32          		sizeimage;
	__u32			colorspace;	/* enum v4l2_colorspace */
	__u32			priv;		/* private data, depends on pixelformat */
	__u32			flags;		/* format flags (V4L2_PIX_FMT_FLAG_*) */
	__u32			ycbcr_enc;	/* enum v4l2_ycbcr_encoding */
	__u32			quantization;	/* enum v4l2_quantization */
	__u32			xfer_func;	/* enum v4l2_xfer_func */
};

struct v4l2_pix_format_mplane {
	__u32				width;
	__u32				height;
	__u32				pixelformat;
	__u32				field;
	__u32				colorspace;

	struct v4l2_plane_pix_format	plane_fmt[VIDEO_MAX_PLANES];
	__u8				num_planes;
	__u8				flags;
	__u8				ycbcr_enc;
	__u8				quantization;
	__u8				xfer_func;
	__u8				reserved[7];
} __attribute__ ((packed));
]]

ffi.cdef[[
struct v4l2_requestbuffers {
	__u32			count;
	__u32			type;		/* enum v4l2_buf_type */
	__u32			memory;		/* enum v4l2_memory */
	__u32			reserved[2];
};
]]

ffi.cdef[[
struct v4l2_rect {
	__s32   left;
	__s32   top;
	__u32   width;
	__u32   height;
};

struct v4l2_clip {
	struct v4l2_rect        c;
	struct v4l2_clip	*next;
};

struct v4l2_window {
	struct v4l2_rect        w;
	__u32			field;	 /* enum v4l2_field */
	__u32			chromakey;
	struct v4l2_clip	*clips;
	__u32			clipcount;
	void			*bitmap;
	__u8                    global_alpha;
};

struct v4l2_vbi_format {
	__u32	sampling_rate;		/* in 1 Hz */
	__u32	offset;
	__u32	samples_per_line;
	__u32	sample_format;		/* V4L2_PIX_FMT_* */
	__s32	start[2];
	__u32	count[2];
	__u32	flags;			/* V4L2_VBI_* */
	__u32	reserved[2];		/* must be zero */
};

/* Sliced VBI
 *
 *    This implements is a proposal V4L2 API to allow SLICED VBI
 * required for some hardware encoders. It should change without
 * notice in the definitive implementation.
 */

struct v4l2_sliced_vbi_format {
	__u16   service_set;
	/* service_lines[0][...] specifies lines 0-23 (1-23 used) of the first field
	   service_lines[1][...] specifies lines 0-23 (1-23 used) of the second field
				 (equals frame lines 313-336 for 625 line video
				  standards, 263-286 for 525 line standards) */
	__u16   service_lines[2][24];
	__u32   io_size;
	__u32   reserved[2];            /* must be zero */
};

struct v4l2_sdr_format {
	__u32				pixelformat;
	__u32				buffersize;
	__u8				reserved[24];
} __attribute__ ((packed));

struct v4l2_format {
        __u32    type;
        union {
                struct v4l2_pix_format          pix;     /* V4L2_BUF_TYPE_VIDEO_CAPTURE */
                struct v4l2_pix_format_mplane   pix_mp;  /* V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE */
                struct v4l2_window              win;     /* V4L2_BUF_TYPE_VIDEO_OVERLAY */
                struct v4l2_vbi_format          vbi;     /* V4L2_BUF_TYPE_VBI_CAPTURE */
                struct v4l2_sliced_vbi_format   sliced;  /* V4L2_BUF_TYPE_SLICED_VBI_CAPTURE */
                struct v4l2_sdr_format          sdr;     /* V4L2_BUF_TYPE_SDR_CAPTURE */
                __u8    raw_data[200];                   /* user-defined */
        } fmt;
};
]]

ffi.cdef[[
struct v4l2_fract {
	__u32   numerator;
	__u32   denominator;
};

struct v4l2_captureparm {
	__u32		   capability;	  /*  Supported modes */
	__u32		   capturemode;	  /*  Current mode */
	struct v4l2_fract  timeperframe;  /*  Time per frame in seconds */
	__u32		   extendedmode;  /*  Driver-specific extensions */
	__u32              readbuffers;   /*  # of buffers for read */
	__u32		   reserved[4];
};

struct v4l2_outputparm {
	__u32		   capability;	 /*  Supported modes */
	__u32		   outputmode;	 /*  Current mode */
	struct v4l2_fract  timeperframe; /*  Time per frame in seconds */
	__u32		   extendedmode; /*  Driver-specific extensions */
	__u32              writebuffers; /*  # of buffers for write */
	__u32		   reserved[4];
};

struct v4l2_streamparm {
	__u32	 type;			/* enum v4l2_buf_type */
	union {
		struct v4l2_captureparm	capture;
		struct v4l2_outputparm	output;
		__u8	raw_data[200];  /* user-defined */
	} parm;
};
]]


-- libv4l2.h
ffi.cdef[[
 int v4l2_open(const char *file, int oflag, ...);
 int v4l2_close(int fd);
 int v4l2_dup(int fd);
 int v4l2_ioctl(int fd, unsigned long int request, ...);
 ssize_t v4l2_read(int fd, void *buffer, size_t n);
 ssize_t v4l2_write(int fd, const void *buffer, size_t n);
 void *v4l2_mmap(void *start, size_t length, int prot, int flags,
		int fd, int64_t offset);
 int v4l2_munmap(void *_start, size_t length);
]]

--load_header "/usr/include/linux/videodev2.h"

local arch = { IOC = nil}

local IOC = arch.IOC or {
  SIZEBITS = 14,
  DIRBITS = 2,
  NONE = 0,
  WRITE = 1,
  READ = 2,
}

IOC.READWRITE = IOC.READ + IOC.WRITE

IOC.NRBITS	= 8
IOC.TYPEBITS	= 8

IOC.NRMASK	= bit.lshift(1, IOC.NRBITS) - 1
IOC.TYPEMASK	= bit.lshift(1, IOC.TYPEBITS) - 1
IOC.SIZEMASK	= bit.lshift(1, IOC.SIZEBITS) - 1
IOC.DIRMASK	= bit.lshift(1, IOC.DIRBITS) - 1

IOC.NRSHIFT   = 0
IOC.TYPESHIFT = IOC.NRSHIFT + IOC.NRBITS
IOC.SIZESHIFT = IOC.TYPESHIFT + IOC.TYPEBITS
IOC.DIRSHIFT  = IOC.SIZESHIFT + IOC.SIZEBITS

local function ioc(dir, ch, nr, size)
  if type(ch) == "string" then ch = ch:byte() end
  return bit.bor(bit.lshift(dir, IOC.DIRSHIFT), 
	     bit.lshift(ch, IOC.TYPESHIFT), 
	     bit.lshift(nr, IOC.NRSHIFT), 
	     bit.lshift(size, IOC.SIZESHIFT))
end


local function _IOC(dir, ch, nr, tp)
	size = ffi.sizeof(tp)
	return ioc(dir, ch, nr, size)
end

-- used to create numbers
local _IO    = function(ch, nr)		return _IOC(IOC.NONE, ch, nr, 0) end
local _IOR   = function(ch, nr, tp)	return _IOC(IOC.READ, ch, nr, tp) end
local _IOW   = function(ch, nr, tp)	return _IOC(IOC.WRITE, ch, nr, tp) end
local _IOWR  = function(ch, nr, tp)	return _IOC(IOC.READWRITE, ch, nr, tp) end

-- used to decode ioctl numbers..Yacon
local _IOC_DIR  = function(nr) return band(rshift(nr, IOC.DIRSHIFT), IOC.DIRMASK) end
local _IOC_TYPE = function(nr) return band(rshift(nr, IOC.TYPESHIFT), IOC.TYPEMASK) end
local _IOC_NR   = function(nr) return band(rshift(nr, IOC.NRSHIFT), IOC.NRMASK) end
local _IOC_SIZE = function(nr) return band(rshift(nr, IOC.SIZESHIFT), IOC.SIZEMASK) end

-- ...and for the drivers/sound files...

IOC.IN		= bit.lshift(IOC.WRITE, IOC.DIRSHIFT)
IOC.OUT		= bit.lshift(IOC.READ, IOC.DIRSHIFT)
IOC.INOUT		= bit.lshift(bit.bor(IOC.WRITE, IOC.READ), IOC.DIRSHIFT)
local IOCSIZE_MASK	= bit.lshift(IOC.SIZEMASK, IOC.SIZESHIFT)
local IOCSIZE_SHIFT	= IOC.SIZESHIFT

local function FOURCC(format)
	bytes = ffi.new("uint8_t[4]", format)
	return bit.bor(bytes[0],
		bit.lshift(bytes[1], 8),
		bit.lshift(bytes[2], 16),
		bit.lshift(bytes[3], 24)
	)
end

return setmetatable({
	VIDIOC_QUERYCAP		=	_IOR('V',  0, "struct v4l2_capability"),
	VIDIOC_ENUM_FMT		=	_IOWR('V',  2, "struct v4l2_fmtdesc"),
	VIDIOC_G_FMT		=	_IOWR('V',  4, "struct v4l2_format"),
	VIDIOC_S_FMT		=	_IOWR('V',  5, "struct v4l2_format"),
	VIDIOC_REQBUFS		=	_IOWR('V',  8, "struct v4l2_requestbuffers"),
	VIDIOC_QUERYBUF		=	_IOWR('V',  9, "struct v4l2_buffer"),
	VIDIOC_QBUF			=	_IOWR('V', 15, "struct v4l2_buffer"),
	VIDIOC_DQBUF		=	_IOWR('V', 17, "struct v4l2_buffer"),
	VIDIOC_STREAMON		=	_IOW('V', 18, "int"),
	VIDIOC_STREAMOFF	=	_IOW('V', 19, "int"),
	VIDIOC_G_PARM		=	_IOWR('V', 21, "struct v4l2_streamparm"),
	VIDIOC_ENUMINPUT	=	_IOWR('V', 26, "struct v4l2_input"),
	VIDIOC_G_INPUT		=	_IOR('V', 38, "int"),

	V4L2_PIX_FMT_YUV420	=	FOURCC('YU12')
}, {
	__index = function(t, k)
		error(string.format("%s not found in v4l2", k))
	end
})

ffi = require "ffi"
cairo = require "gui.cairo"
v4l2 = require "camera.v4l2"
video = require "video.init"


jit.off() -- Required because of bug in v4l2 wrapper

local width, height = 640, 480

local camera = v4l2.open(width, height)
-- V4L2 might choose a different resolution than requested
width, height = camera.width, camera.height
print ("Camera Resolution: ", width, "x", height)

local window = video.create_window(width, height)



while video.update_window(window) do
    y, u, v = camera:read_frame()
    if y ~= nil then
        
        surface =  cairo.cairo_image_surface_create_for_data(y, cairo.CAIRO_FORMAT_A8, width, height, width);
        cr = cairo.cairo_create(surface)
        
        cairo.cairo_set_operator(cr, cairo.CAIRO_OPERATOR_DARKEN)
        
        pattern = cairo.cairo_pattern_create_linear(width*1/4, height*1/4, width *3/4, height *3/4)
        cairo.cairo_pattern_add_color_stop_rgba(pattern, 0.0, 1.0, 1.0, 1.0, 0.0)
        cairo.cairo_pattern_add_color_stop_rgba(pattern, 1.0, 0.0, 0.0, 0.0, 1.0)

        cairo.cairo_rectangle(cr, 20, height *2/3, width - 40, 140);
        cairo.cairo_set_source(cr, pattern);
        cairo.cairo_fill(cr);

        
        cairo.cairo_set_operator(cr, cairo.CAIRO_OPERATOR_SOURCE)
        
        cairo.cairo_set_source_rgba(cr, 0, 0, 0, 0.0)
        cairo.cairo_select_font_face(cr, "Sans", cairo.CAIRO_FONT_SLANT_NORMAL, cairo.CAIRO_FONT_WEIGHT_NORMAL)
        cairo.cairo_set_font_size(cr, 40.0)
        
        cairo.cairo_move_to(cr, 35, height *2/3 + 80)
        cairo.cairo_show_text(cr, "eWindow is making progress...");

        cairo.cairo_destroy(cr)
        cairo.cairo_surface_destroy(surface)
    
        video.update_texture(window, y, u, v)
	  end
end

camera:close()

include <constants.scad>;

/*  returns centre of alignment pattern if specified pixel is within an alignment pattern for the specified version
    
    returns [] if not
*/
function is_in_alignment(x, y, version) = let(
    locs = alignment_locs[version-1],
    xm = [for (i=locs) if (x>=i-2 && x<=i+2) i][0],
    ym = [for (i=locs) if (y>=i-2 && y<=i+2) i][0],
    last = (version*4+10),
    collision = (xm==6 && ym==6) || (xm==6 && ym==last) || (xm==last && ym==6))
    xm && ym && !collision? [xm,ym] : [];

/* returns module value for a point within an alignment pattern
   x0,y0 : module coordinates 
   align_center : centre point of pattern
*/
function get_alignment_module(x0, y0, align_centre) = let(
    x = x0 - align_centre[0],
    y = y0 - align_centre[1])
    x==-2 || x==2 ? 1 :
    y==-2 || y==2 ? 1 :
    x==0 && y==0 ? 1 : 0;


/* returns true if given module is in the formatting area */    
function is_in_format(x, y, size) = 
    x==8 && (y<=8 || y>=size-8)? true :
    y==8 && (x<=8 || x>=size-8)? true : false;
    
/* returns true if given module is in the version area */
function is_in_version(x, y, size, version) = 
    version < 7 ? false:
    x<6 && y>=size-11 && y<=size-9 ? true :
    y<6 && x>=size-11 && x<=size-9 ? true : false;

/* return module value for a point within version pattern */    
function get_version_module(x, y, size, version) = let(
    ver_code = version_codes[version-7],
    x_off = x>y? x-(size-11): y-(size-11),
    y_off = x>y? y : x,
    index = 17-(x_off+y_off*3))
    //[x_off, y_off, index];
    ver_code[index];
    

/* returns true if given module is in a finder area */
function is_in_finder(x, y, size) = 
    (x<8 && y <8) || (x<8 && y>=size-8) || (x>=size-8 && y<8);
    
/* returns module value for a point within a finder pattern
   x0,y0 :  module coordinates
   x_off, y_off : coordinates of top left module in finder pattern
*/
function get_finder_module(x0, y0, size) = let(
    x_off = x0>=size-8? size-7 : 0,
    y_off = y0>=size-8? size-7 : 0,
    x = x0-x_off,
    y = y0-y_off)
    x==-1 || x== 7 ? 0: //separator
    y==-1 || y== 7 ? 0: 
    x==0 || x==6 ? 1 : //outer box
    y==0 || y==6 ? 1 : 
    x==1 || x==5 ? 0 : //middle space
    y==1 || y==5 ? 0 :
    1; //central box    

/*return the relevant module for a location within a template
    input:
      version: version of qr code
      size: size of qr code in modules
      x: x-axis coordinate
      y: y-axis coordinate
    output:
      undef = not set
      0 = white
      1 = black
*/
function template_module(x, y, size, version) = let(
    in_finder = is_in_finder(x, y, size),
    in_timing_band = x==6 || y==6,
    in_dark_mod = x==8 && y==size-8,
    in_alignment = is_in_alignment(x, y, version),
    in_format = is_in_format(x, y, size),
    in_version = is_in_version(x, y, size, version))
    in_finder ? get_finder_module(x, y, size) :
    in_alignment ? get_alignment_module(x, y, in_alignment) :
    in_timing_band ? (x+y+1) % 2 :
    in_dark_mod ? 1: 
    in_format ? 0: 
    in_version ? get_version_module(x, y, size, version): undef;  //FIXME add version info
    
/* create a template for a given version 
   undef = available for data
   0 = white
   1 = black
*/
function make_basic_template(version) = let(
    size = version*4+17)
    [for (x=[0:size-1]) [for (y=[0:size-1]) template_module(x, y, size, version)]];

/* create a mapping for each bit of a column, going up*/
function map_up_column(template, col, size) = 
    [for (y1=[0:size]) let(y=size-y1) 
        [for (x=[0:1]) 
            if (template[col-x][y]==undef) 
                [col-x,y]]];
            
/* create a mapping for each bit of a column, going down*/
function map_down_column(template, col, size) = 
    [for (y=[0:size])
        [for (x=[0:1]) 
            if (template[col-x][y]==undef) 
                [col-x,y]]];

/* create a mapping for each bit of content to a position in the QRcode
   returns a list of coordinates for each bit in sequence    
*/
function make_mapping(template, up = true, col=undef) = let(
    size = len(template)-1,
    c = col== undef ? size : 
        col==6 ?5 : col)//adjust for vertical timing row
    c<=0? []:
    up ? concat(map_up_column(template,c,size),make_mapping(template,false,c-2))
       : concat(map_down_column(template,c,size),make_mapping(template,true,c-2));
            
function image_module(x, y, data, template, map, version, ec_code, mask) = 
    template[x][y]!=undef? template[x][y]:data[search([[x,y]],map)[0]];
            
function make_image(data, template, map, version, ec_code, mask) = let(
    size = len(template)-1)
    [for (x=[0:size]) [for (y=[0:size]) image_module(x, y, data, template, map, version, ec_code, mask)]];


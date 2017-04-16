use <util.scad>;
use <polynom.scad>;
include <constants.scad>;


//convert a character into its UTF/ascii value
function ord(char) = search(char, chr([32:128]))[0]+32;

//Fix if using mode not binary
function encoding_mode(mode) = [0,1,0,0];

//fix if using mode not binary
function character_count(mode, data) = bittify(len(data), 8);


/*take some text data, and convert into a binary data section
 converts from string data to bytes, adds mode bytes and  count_length
 bytes as a length indicator and pads out to max_length as per qrcode spec
 */
function make_data(data, max_length, count_length = 8) = let(
    data_codes = [for (i=[0:len(data)-1]) ord(data[i])], // convert data to byte values...
    d1 = concat([0,1,0,0], bittify(len(data_codes), count_length), bytes_to_bits(data_codes)),
    d2 = concat(d1, vecfill(0,min(4, max_length*8 - len(d1)))), //add up to 4 padding zeroes
    d3 = concat(d2, vecfill(0,(8-len(d2) % 8) % 8)), //fill up to a full bytes
    d4 = concat(d3, bytes_to_bits([for (i = [1:max_length-len(d3)/8]) i%2?236:17])),
    d5 = bits_to_bytes(d4))
    d5;


// take a sequence of bytes and convert into num_codes error codes
function make_error_codes(data, num_codes) = let(
    rsPoly = base_polynomials[num_codes],
    lout = len(rsPoly) - 1,
    rawPoly = new_poly(data, lout),
    modPoly = mod_poly(rawPoly, rsPoly),
    offset = len(modPoly) - lout)
    //rawPoly;
    [for (i=[0:lout-1]) (i+offset)>=0?modPoly[i+offset]:0];



/* input:
     block_list: a list of block descriptors as returned by get_block_info
     data: a list of bytes as created by make_data
     data_blocks: a list of blocks of data, chunked as per block_list
     error_blocks: a list of blocks of EC codes, chunked as per block list
   output:
     [data_blocks, error_blocks] 
*/ 
function make_blocks(block_list, data, data_blocks=[], error_blocks=[]) = let(
    data_block_len = block_list[0][0],
    error_code_len = block_list[0][1]-data_block_len,
    data_block = head(data, data_block_len))
    len(block_list)==0? [data_blocks, error_blocks] : 
        make_blocks(tail(block_list), 
                      tail(data, data_block_len),
                      concat(data_blocks, [data_block]),
                      concat(error_blocks, [make_error_codes(data_block, error_code_len)]));


/* get block information for given version and error correction level
   returns [max_length, [[block_data_length, total_block_length], ...]
*/
function get_block_info(version, code) = let(
    index = search(code,block_details),
    desc = block_details[index[0]][1][version-1][1],
    max_length = block_details[index[0]][1][version-1][0],
    d1 = vecfill([desc[2],desc[1]],desc[0]),
    d2 = len(desc)>3 ? vecfill([desc[5],desc[4]],desc[3]): [])
    [max_length,concat(d1,d2)];
    

/* take a length of data and error_correction level, 
   find smallest QR version that can hold this data.
*/
function find_version(data_len, ec_code) = let(
    index = search(ec_code,block_details),
    desc = block_details[index[0]][1],
    impossibles = [for (i=desc) if ((i[0]-3)<data_len) 1])
    len(impossibles)+1;

/* interleave blocks as per qr spec:
   input:
     blocks: a list of lists of values
   output: a list of values
   example:
    input blocks: [[a1,a2,a3],[b1,b2,b3,b4],[c1,c2,c3,c4]]
    output [a1,b1,c1,a2,b2,c2,a3,b3,c3,b4,c4]
*/
function interleave(blocks) = let(
    max_len = max([for (i=blocks) len(i)]))
    [for (i=[0:max_len-1]) for (j = blocks) if (i<len(j)) j[i]];    
        
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

/* returns true if given module is in the formatting area */    
function is_in_format(x, y, size) = 
    x==8 && (y<=8 || y>=size-8)? true :
    y==8 && (x<=8 || x>=size-8)? true : false;
    
/* returns true if given module is in the version area */
function is_in_version(x, y, size, version) = 
    version < 7 ? false:
    x<6 && y>=size-11 && y<=size-9 ? true :
    y<6 && x>=size-11 && x<=size-9 ? true : false;
    
function get_version_module(x, y, size, version) = let(
    ver_code = version_codes[version-7],
    x_off = x>y? x-(size-11): y-(size-11),
    y_off = x>y? y : x,
    index = 17-(x_off+y_off*3))
    //[x_off, y_off, index];
    ver_code[index];
    

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

/* returns module value for a point within a finder pattern
   x0,y0 :  module coordinates
   x_off, y_off : coordinates of top left module in finder pattern
*/
function get_finder_module(x0, y0, x_off, y_off) = let(
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
    in_finder = (x<8 && y <8) || (x<8 && y>=size-8) || (x>=size-8 && y<8),
    finder_x_offset = x>=size-8? size-7 : 0,
    finder_y_offset = y>=size-8? size-7 : 0,
    in_timing_band = x==6 || y==6,
    in_dark_mod = x==8 && y==size-8,
    in_alignment = is_in_alignment(x, y, version),
    in_format = is_in_format(x, y, size),
    in_version = is_in_version(x, y, size, version))
    in_finder ? get_finder_module(x, y, finder_x_offset, finder_y_offset) :
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
/* create a qrcode
   input:
      data: a string to be encoded
      ec_code: error correction level, one of "L", "M", "Q", "H"
      version(optional): what version QR code if left undefined, optimal size
                         will be selected
*/
            
function image_module(x, y, data, template, map, version, ec_code, mask) = 
    template[x][y]!=undef? template[x][y]:data[search([[x,y]],map)[0]];
            
function make_image(data, template, map, version, ec_code, mask) = let(
    size = len(template)-1)
    [for (x=[0:size]) [for (y=[0:size]) image_module(x, y, data, template, map, version, ec_code, mask)]];
            
function make_qrcode(data, ec_code="M", version=undef) = let(
    //determine ideal version
    v = version==undef ?find_version(len(data), ec_code) :version,
    t1 = get_block_info(v, ec_code),
    max_length = t1[0],
    block_info = t1[1],
    data_sequence = make_data(data, max_length), //FIXME - need to update count_length depending on version
    blocks = make_blocks(block_info,data_sequence),
    iblocks = concat(interleave(blocks[0]), interleave(blocks[1])),
    content = bytes_to_bits(iblocks),
    template = make_basic_template(v),
    map = flatten(make_mapping(template)))
    //create mapping for data
    //create your 9 test codes
    //test each code
    //select best one
    //return it
    iblocks;

module instantiate_code(pattern) {
    maxi = len(pattern);
    maxj = max([for (i=pattern) len(i)]);
    for (i = [0:maxi-1]) {
        for (j = [0:maxj-1]) {
            if (pattern[i][j]==0) 
                translate([i,-j,0]) cube([1,1,1]);
            if (pattern[i][j]==1)
                color("black") translate([i,-j,0]) cube([1,1,2]);
        }
    }
}

/*
    Testing section
*/
URL="http://www.google.com";

blocks = make_qrcode(URL,"Q",version=7);
template = make_basic_template(7);
map = flatten(make_mapping(template));
image = make_image(bytes_to_bits(blocks), template, map, 3, "Q", 0);
instantiate_code(image);

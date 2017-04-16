use <util.scad>;
use <polynom.scad>;
use <image.scad>;
use <analyse.scad>;
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
        

            
/* create a qrcode
   input:
      data: a string to be encoded
      ec_code: error correction level, one of "L", "M", "Q", "H"
      version(optional): what version QR code if left undefined, optimal size
                         will be selected
*/
function make_qrcode(data, ec_code="M", version=undef) = let(
    //determine ideal version
    v = version==undef ?find_version(len(data), ec_code) :version,
    t1 = get_block_info(v, ec_code),
    max_length = t1[0],
    block_info = t1[1],
    data_sequence = make_data(data, max_length), //FIXME - need to update count_length depending on version
    blocks = make_blocks(block_info,data_sequence),
    iblocks = concat(interleave(blocks[0]), interleave(blocks[1]),[0]),
    content = bytes_to_bits(iblocks),
    template = make_basic_template(v),
    //create mapping for data
    map = flatten(make_mapping(template)),
    //create your 9 test codes
    images = [for (i=[0:7]) make_image(bytes_to_bits(iblocks), template, map, v, ec_code, i)],
    //test each code
    scores = [for (i=images) score(i)],
    //select best one
    image = images[search(min(scores),scores)[0]])
    //return it
    image;

module instantiate_code(pattern) {
    maxi = len(pattern);
    maxj = max([for (i=pattern) len(i)]);
    for (i = [0:maxi-1]) {
        for (j = [0:maxj-1]) {
            if (pattern[i][j]==0) 
                color("white") translate([i,-j,0]) cube([1,1,1]);
            if (pattern[i][j]==1)
                color("black") translate([i,-j,0]) cube([1,1,1]);
        }
    }
}

/*
    Testing section
*/
URL="I think my QR code is finally working...";
instantiate_code(make_qrcode(URL));

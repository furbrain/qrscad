use <util.scad>;
include <constants.scad>;

digits = "0123456789";
alnum = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";

NUMERIC = 1;
ALNUM = 2;
BYTE = 4;

//convert a character into its UTF/ascii value
function ord(char) = search(char, chr([32:128]))[0]+32;

//Fix if using mode not binary
function encoding_mode(mode) = [0,1,0,0];

//fix if using mode not binary
function character_count(mode, data) = bittify(len(data), 8);


/* encode data using specified mode */


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

/* find encoding mode
*/
function find_encoding(data) = let(
    ldata = len(data),
    lnum = len(flatten(search(digits, data, num_returns_per_match=0))),
    lalnum = len(flatten(search(digits, data, num_returns_per_match=0))))
    ldata==lnum ? NUMERIC:
    ldata==lalnum ? ALNUM: BYTE;

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
        


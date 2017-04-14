use <util.scad>;
use <polynom.scad>;
URL="http://www.google.com";

//convert a character into its UTF/ascii value
function ord(char) = search(char, chr([32:128]))[0]+32;



function error_correction_mode_bits() = 1;

//Fix if using mode not binary
function encoding_mode(mode) = [0,1,0,0];

//fix if using mode not binary
function character_count(mode, data) = bittify(len(data), 8);


//take some text data, and convert into a binary data section
function make_data(data, max_length, count_length = 8) = let(
    data_codes = [for (i=[0:len(data)-1]) ord(data[i])], // convert data to byte values...
    d1 = concat([0,1,0,0], bittify(len(data_codes)-1, count_length), bytes_to_bits(data_codes)),
    d2 = concat(d1, vecfill(0,min(4, max_length*8 - len(d1)))), //add up to 4 padding zeroes
    d3 = concat(d2, vecfill(0,(8-len(d2) % 8) % 8)), //fill up to a full bytes
    d4 = concat(d3, bytes_to_bits([for (i = [1:max_length-len(d3)/8]) i%2?236:17])),
    d5 = bits_to_bytes(d4))
    d5;

echo(make_data(URL,max_length=34));

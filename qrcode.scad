URL="http://furbrain.org.uk/";

//convert a character into its UTF/ascii value
function ord(char) = search(char, chr([32:128]))[0]+32;



function error_correction_mode_bits() = 1;

//Fix if using mode not binary
function encoding_mode(mode) = [0,1,0,0];

//fix if using mode not binary
function character_count(mode, data) = bittify(len(data), 8);


//padding code
function pad1(l, m) = min(4,m-l);
function pad_byte(l,m) = (8 - ((l+pad1(l,m)) % 8)) % 8;
function pad_count(l, m) = pad1(l, m) + pad_byte(l, m);
function zero_pad(data, max_length) = concat(data, [for (i=[1:pad_count(len(data), max_length)]) 0]);
function extra_padding(l) = bytes_to_bits([for (i = [1:l/8]) i%2?17:236]);
function pad_remainder(data, max_length) = concat(data, extra_padding(max_length-len(data)));


function do_padding(data, max_length)  = let (d1 = zero_pad(data,max_length)) pad_remainder(d1,max_length);
data_bytes = [for (i=[0:len(URL)-1]) ord(URL[i])];
data_bits = bytes_to_bits(data_bytes);


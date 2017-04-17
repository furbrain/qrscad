use <util.scad>;
use <polynom.scad>;
use <image.scad>;
use <encode.scad>;
use <analyse.scad>;
include <constants.scad>;
            
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

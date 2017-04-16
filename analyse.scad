use <util.scad>;


//score length-2 for all consecutive runs >=5 in length
// needs to be run against transpose as well
function penalty1(image) = let(
    d0 = concat(image, transpose(image)),
    d1 = flatten([for (i=d0) run_length_encode(i)]),
    d2 = [for (i=d1)  if (i>=5) i-2])
    sum(d2); 

function is_square(x, y, i) = 
    i[x][y]==0 && i[x][y+1]==0 && i[x+1][y]==0 && i[x+1][y+1]==0 ? true :
    i[x][y]==1 && i[x][y+1]==1 && i[x+1][y]==1 && i[x+1][y+1]==1 ? true :
    false;
    

//score 3 for every 4x4 contiguous square found
function penalty2(image) = let(
    maxx = len(image)-2,
    maxy = len(image[0])-2,
    squares = [for (x=[0:maxx]) for (y=[0:maxy]) if (is_square(x, y, image)) [x,y]])
    len(squares)*3; 

//score 40 for specific patterns    
function penalty3(image) = let(
    d0 = concat(image, transpose(image)),
    l = len(d0[0])-11,
    match1 = [for (x=d0) for(y=[0:l]) if (bits_to_byte(slice(x,y,y+11))==1488) 40],
    match2 = [for (x=d0) for(y=[0:l]) if (bits_to_byte(slice(x,y,y+11))==93) 40])
    sum(flatten(match1)) + sum(flatten(match2));


//score for uneven black/white distribution.    
function penalty4(image) = let(
    denom = len(image)*len(image[0]),
    num = sum(flatten(image)),
    frac = abs(0.50-num/denom)*20,
    res = floor(frac)*10)
    res;
    
/* return penalty score for given image 
   score: a list of lists of 1s and 0s representing a candidate qr code
   returns an integer, lower is better
   */
function score(image) = penalty1(image) + penalty2(image) + penalty3(image) + penalty4(image);

    
/* TESTING */    
    
echo(penalty1([[0,0,0,0,0,1],
               [1,0,1,0,1,1],
               [0,1,0,1,0,1],    
               [0,1,0,1,0,1],    
               [0,1,0,1,0,1],    
               [0,1,0,1,0,1]])); //==7    
               
echo(penalty2([[0,0],[0,0]])); //==3
echo(penalty2([[1,1],[1,1]])); //==3
echo(penalty2([[0,0,0],[0,0,0],[0,0,0],[0,0,0]])); //==18

echo(penalty3([[0,0,0,0,1,0,1,1,1,0,1],
               [0,0,0,0,0,0,0,0,0,0,0],
               [0,0,0,0,0,0,0,0,0,0,1],
               [0,0,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,0,1],
               [0,0,0,0,0,0,0,0,0,0,0],
               [1,0,0,0,0,0,0,0,0,0,1],
               [1,0,0,0,0,0,0,0,0,0,0],
               [1,0,0,0,0,0,0,0,0,0,0],
               [0,0,0,0,0,0,0,0,0,0,0],
               [1,0,0,0,0,0,0,0,0,0,0]])); //==120
               
echo(penalty4([[0,0,1,1,1,0],[1,1,0,1,1,1]])); //==30

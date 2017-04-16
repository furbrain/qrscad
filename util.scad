//fill a vector with values
function vecfill(value,count) = count==0?[]:[for (i=[1:count]) value];

//python style slice
function slice(a, start=0, end=undef, step=1) = let(
    begin = start>=0 ? start : len(a)+start,
    finish = end==undef ? len(a) : (end >= 0 ? end : len(a)+end))
    finish-1<begin ? [] : [for (i=[begin:step:finish-1]) a[i]];
function tail(a, d=1) = slice(a,d);
function head(a, d=1) = slice(a,0,d);

//convert a byte into 8 bits

function bittify(value, bits) = [for (i = [0:bits-1]) floor(value/pow(2, bits-1-i)) % 2];
function bytes_to_bits(bytes) = [for (a=bytes) for (b=bittify(a, 8)) b];
function bits_to_byte(a, result=0) = 
    len(a)==1 ? a[0] +result : bits_to_byte(tail(a), 2*(result +a[0]));
function bits_to_bytes(arr) = [for (i=[0:8:len(arr)-1]) bits_to_byte(slice(arr,i,i+8))];


function xor(a,b) = let(
    a_bits = bittify(a,8),
    b_bits = bittify(b,8),
    xor_bits = [for (i=[0:7]) (a_bits[i]==b_bits[i]) ? 0 : 1])
    bits_to_byte(xor_bits);

function ixor(arr) = let (l=len(arr)) l==1? arr[0]: 
                                    l==2? xor(arr[0],arr[1])
                                        : xor(ixor(head(arr)),arr[l-1]);

function flatten(arr) = [for (a=arr) for (b=a) b];

function transpose(arr) = let(
    maxi = len(arr)-1,
    maxj = len(arr[0])-1)
    [for (j=[0:maxj]) [for (i=[0:maxi]) arr[i][j]]];
    
function run_length_encode(arr, result=[], last=undef, length=0) =
    len(arr)==0 ? tail( concat(result,[length])) : 
    last==arr[0] ? run_length_encode(tail(arr), result, last, length+1) :
                   run_length_encode(tail(arr), concat(result,[length]), arr[0], 1);
                   
function sum(arr, result=0) = 
    len(arr)==0? result : sum(tail(arr),result+arr[0]);
    
echo(transpose([[1,2,3,4],[5,6,7,8],[9,10,11,12]]));
echo(run_length_encode([0,0,0,0,1,1,1,1,1,2,3,3,0,0,0]));
echo(sum([1,4,5,10]));

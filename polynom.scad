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
function bits_to_byte(a) = a[0]*128 + a[1]*64 + a[2]*32 + a[3]*16 +a[4]*8 + a[5]*4 +a[6]*2 + a[7];
function bits_to_bytes(arr) = [for (i=[0:8:len(arr)-1]) bits_to_byte(slice(arr,i,i+7))];


function xor(a,b) = let(
    a_bits = bittify(a,8),
    b_bits = bittify(b,8),
    xor_bits = [for (i=[0:7]) (a_bits[i]==b_bits[i]) ? 0 : 1])
    bits_to_byte(xor_bits);

function ixor(arr) = let (l=len(arr)) l==1? arr[0]: 
                                    l==2? xor(arr[0],arr[1])
                                        : xor(ixor(head(arr)),arr[l-1]);

function mk_exp_table(count) = let(
    t = (count>8)? mk_exp_table(count-1): [],
    l = len(t))
    (count==8) ? [for (i=[0:7]) pow(2,i)] : 
    concat(t,[xor(xor(t[l-4],t[l-5]),xor(t[l-6],t[l-8]))]);

EXP_TABLE = mk_exp_table(256);
LOG_TABLE = concat([0],search([for(i=[1:255]) i],EXP_TABLE));
function glog(a) = LOG_TABLE[a];
function gexp(a) = EXP_TABLE[a % 255];



function get_offset(a, count=0) = a[0]!=0 ? count : get_offset(tail(a),count+1);
    

function new_poly(num, shift = 0) = let(
   offset = get_offset(num),
   p1 = [for (i=[0:len(num)-offset-1]) num[i+offset]],
   p2 = vecfill(0,shift))
   concat(p1,p2);
   
   
function sub_mul(arr, la, lb, x) = let(
   maxi = min(la-1,x),
   mini = max(x-lb+1,0))
   ixor([for (i=[mini:maxi]) arr[i][x-i]]);
       
   
function mul_poly(a,b) = let(
   la = len(a),
   lb = len(b),
   exparray = [for (i=[0:la-1]) [for (j=[0:lb-1]) gexp(glog(a[i]) +glog(b[j]))]],
   num = [for (i = [0:la+lb-2]) sub_mul(exparray,la,lb,i)])
   new_poly(num,0);
   
function mod_poly(a,b) = let(
   diff = len(a)-len(b),
   minl = min(len(a),len(b)),
   ratio = glog(a[0]) - glog(b[0]),
   num = [for (i=[0:minl-1]) xor(a[i],gexp(glog(b[i])+ratio))],
   ext = diff?slice(a,-diff):[])
   diff<0 ? a 
        //: num;
        : mod_poly(new_poly(concat(num,ext),0),b);
              
p1 = new_poly([1,2,3,4,5,6]);
p2 = new_poly([6,102,7,12]);
echo(mod_poly(p1,p2));
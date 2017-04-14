use <util.scad>;

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

import math
G=1.22; D1=12.0
def D(t): return D1*G**(t-1)
def value(t): return 10*2**(t-1)
PREM=1.06
def price(t): return 10 if t==1 else value(t)*1.25*PREM**(t-1)
def btcost(t): return 5*price(t)
E=[1,4,7,11,14,18,21,25,28,32]; S=[1,1,1,1.5,2,2,2.5,3,3,3]; N=[5,8,10,12,14,15,16,17,18,20]
def nice(x):
    if x<20: return max(1,round(x))
    p=10**(len(str(int(x)))-2); return int(round(x/p)*p)
Z=[]
for z in range(10):
    e=E[z]; hp=nice(D(e)*S[z]*6) if z>0 else 60
    I=20 if z==0 else 0.5*value(e)
    c=nice(I/(N[z]-1+3)); ec=3*c
    Z.append((N[z]-1,hp,3*hp,c,ec))
SLOT={2:None,3:None}
SLOT[2]=2500; SLOT[3]=2000000
def sim(mult,target,boost=1):
    cash=30; inv={}; bt=1; slots=1; t=0; best=0; reached={}; runs=0; maxjump=0
    def add(k,n):
        inv[k]=inv.get(k,0)+n
        while inv.get(k,0)>=2 and k<35:
            m=inv[k]//2; inv[k]-=2*m; inv[k+1]=inv.get(k+1,0)+m; k+=1
    while best<target and runs<3000:
        ws=[]
        for k in sorted(inv,reverse=True): ws+=[k]*inv[k]
        dps=sum(D(k) for k in ws[:slots]) or D(1)
        inc=0; rt=20; zc=0
        for (n,hp,ehp,c,ec) in Z:
            if hp/dps>9: break
            rt+=(n*hp+ehp)/dps+12; inc+=(n*c+ec)*mult*boost; zc+=1
        runs+=1; t+=rt; cash+=inc
        if slots<3 and SLOT[slots+1]>cash and SLOT[slots+1]<=cash+inc*2: pass
        else:
            if slots<3 and SLOT[slots+1]<=cash: cash-=SLOT[slots+1]; slots+=1
            while bt<35 and btcost(bt+1)<=cash*0.5 and best>=bt+2: cash-=btcost(bt+1); bt+=1
            p=price(bt); n=int(cash//p); cash-=n*p; add(bt,n)
        nb=max([k for k in inv if inv[k]>0] or [0])
        maxjump=max(maxjump,nb-best) if best>0 else 0
        best=nb
        if best not in reached: reached[best]=(round(t/60,1),runs,zc)
    return reached,t,maxjump
if __name__=="__main__":
    for z,r in enumerate(Z): print("Z",z+1,"entry",E[z],r,"run inc",r[0]*r[3]+r[4])
    print("slot2",SLOT[2],"slot3",SLOT[3])
    for boost in (1,2,4,16):
        out=[]
        for mult,tg in [(1,9),(2,14),(3,19),(4,24),(5,29),(6,34)]:
            r,t,j=sim(mult,tg,boost); out.append(f"T{tg}:{round(t/60)}m/j{j}")
        print("boost x",boost," ".join(out))

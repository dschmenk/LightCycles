import math, sys

DEG_PER_CIRCLE = 128
DEG_TO_RAD     = math.pi*2/DEG_PER_CIRCLE

print 'SIN_TBL'
for angle in xrange(DEG_PER_CIRCLE+DEG_PER_CIRCLE/4):
    if angle == DEG_PER_CIRCLE/4:
        print 'COS_TBL'
    sincos = math.sin(angle*DEG_TO_RAD)
    fxs  = int(math.floor(sincos*127.0))
    if fxs < 0:
        fxs += 256
    print '\t!BYTE\t$%03X\t; angle %d' % (fxs, angle)
 

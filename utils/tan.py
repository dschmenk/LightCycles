import math, sys

DEG_PER_CIRCLE = 128
DEG_TO_RAD     = math.pi*2/DEG_PER_CIRCLE

print 'TAN_TBL'
for angle in xrange(DEG_PER_CIRCLE/4):
    tan = math.tan(angle*DEG_TO_RAD)
    fxt = int(math.floor(tan*256.0+0.5))
    print '\t!WORD\t$%04X\t; angle %d' % (fxt, angle)
 

import pygame, math, sys
from pygame.locals import *

DEG_PER_CIRCLE = 128
DEG_TO_RAD     = math.pi*2/DEG_PER_CIRCLE
FOV            = DEG_PER_CIRCLE/3 # FOV in degrees
PROJDIST       = 0.5 #1.5  # Distance to projection plane
PROJHEIGHT     = 2.0  # Height of projection screen
PROJBOT        = 1.5 # Bottom of projection screen
PROJTOP        = PROJBOT+PROJHEIGHT # Top of projection screen
EYEHEIGHT      = PROJBOT+PROJHEIGHT/2 # Eye height
HORIZON        = 16#200

tex1 = [[(0,0,0),(255,0,0)],[(0,255,0),(0,0,255)]]
s =  [[0 for x in xrange(DEG_PER_CIRCLE)] for y in xrange(255)]
t =  [[0 for x in xrange(DEG_PER_CIRCLE)] for y in xrange(255)]
ds = [[0 for x in xrange(DEG_PER_CIRCLE)] for y in xrange(255)]
dt = [[0 for x in xrange(DEG_PER_CIRCLE)] for y in xrange(255)]

def setup(width, height):
    global HORIZON
    global s, t, ds, dt

    print 'ST_TBL			; S, T, DS, DT angle+scanline table'
    pixfov  = math.tan(FOV/2*DEG_TO_RAD) / width/2
    for angle in xrange(DEG_PER_CIRCLE):
        viewv   = math.sin(angle*DEG_TO_RAD)
        viewu   = math.cos(angle*DEG_TO_RAD)
        scanv   =  viewu # sin((dirview+90)*DEG_TO_RAD)
        scanu   = -viewv # cos((dirview+90)*DEG_TO_RAD)
        for scanline in xrange(0, height):
            if scanline >= HORIZON:
                break
            scanheight = scanline * PROJHEIGHT / height + PROJBOT
            if scanheight >= EYEHEIGHT:
                break
            scandist = EYEHEIGHT * PROJDIST / (EYEHEIGHT - scanheight)
            if scandist > PROJDIST and scandist < 256:
                s[scanline][angle]  = viewu * scandist
                t[scanline][angle]  = viewv * scandist
                dp = pixfov * scandist
                ds[scanline][angle] = scanu * dp
                dt[scanline][angle] = scanv * dp
                fxs  = int(math.floor(s[scanline][angle]*1024+0.5))
                fxt  = int(math.floor(t[scanline][angle]*1024+0.5))
                fxds = int(math.floor(ds[scanline][angle]*65536+0.5))
                fxdt = int(math.floor(dt[scanline][angle]*65536+0.5))
#                fxs  = int(s[scanline][angle]*1024+0.5) # 6.10 fixpt
#                fxt  = int(t[scanline][angle]*1024+0.5) # 6.10 fixpt
#                fxds = int(ds[scanline][angle]*65536+0.5)   # 0.16 fixpt
#                fxdt = int(dt[scanline][angle]*65536+0.5)   # 0.16 fixpt
                if fxs < 0:
                    fxs += 65536
                if fxt < 0:
                    fxt += 65536
                if fxds < 0:
                    fxds += 65536
                if fxdt < 0:
                    fxdt += 65536
                print '\t!WORD\t$%04X, $%04X, $%04X, $%04X\t;scan %d angle %d' % (fxs, fxt, fxds, fxdt, scanline, angle)
                if scanline > HORIZON:
                    HORIZON = scanline

def texel(s, t):
    return tex1[int(math.floor(s))&1][int(math.floor(t))&1]

def draw(pixbuf, width, height, frame):
    xview   = 0
    yview   = 0
    dirview = frame%DEG_PER_CIRCLE
    for scanline in xrange(HORIZON):
        _s  = xview + s[scanline][dirview]
        _t  = yview + t[scanline][dirview]
        #
        # Draw right half of scanline
        #
        _ds = ds[scanline][dirview]
        _dt = dt[scanline][dirview]
        scans = _s + _ds / 2
        scant = _t + _dt / 2
        for x in xrange(width/2, width):
            pixbuf[x][(height-1)-scanline] = texel(scans, scant)
            scans += _ds
            scant += _dt
        #
        # Draw left half of scanline
        #
        scans = _s - _ds / 2
        scant = _t - _dt / 2
        for x in xrange(width/2-1, -1, -1):
            pixbuf[x][(height-1)-scanline] = texel(scans, scant)
            scans -= _ds
            scant -= _dt

WIDTH = 30#320
HEIGHT = 40#200
pygame.init()
surface = pygame.display.set_mode((WIDTH,HEIGHT))
surfpix = pygame.PixelArray(surface)
frame   = 0
setup(WIDTH, HEIGHT)
while True:
    draw(surfpix, WIDTH, HEIGHT, frame)
    pygame.display.update()
    frame += 1
    for event in pygame.event.get():
        if event.type == QUIT or (event.type == KEYDOWN and event.key == K_ESCAPE):
            pygame.quit()
            sys.exit()


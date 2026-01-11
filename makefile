LIGHTCYCLES = LIGHTCYCLES.BIN
#
# Image filetypes for Virtual ][
#
PLATYPE	= .\$$ED
BINTYPE	= .BIN
SYSTYPE	= .SYS
TXTTYPE	= .TXT
#
# Image filetypes for CiderPress
#
#RELTYPE	= \#FE1000
#INTERPTYPE	= \#050000
#BINTYPE	= \#060000
#SYSTYPE	= \#FF2000
#TXTTYPE	= \#040000

all: $(LIGHTCYCLES)

clean:
	-rm $(LIGHTCYCLES)

$(LIGHTCYCLES): lightcycles.asm intro.asm drawview.asm utils.asm grnd_st.asm sincos.asm tan.asm
	acme --outfile $(LIGHTCYCLES) lightcycles.asm


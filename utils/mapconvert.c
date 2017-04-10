#include <stdio.h>
#include <stdlib.h>

int scancmp(unsigned char bytes1[], unsigned char bytes2[], int len)
{
	int i;
	
	for (i = 0; i < len; i++)
		if (bytes1[i] != bytes2[i])
			return -1;
	return 0;
}
int main(int argc, char **argv)
{
	char type[4];
	int width, height, bytecount, bitcount, bit, prevbit, repeat, rle, linelen, prevlen;
	unsigned char scanline[256], prevline[256];
	
	scanf("%s\n%d %d\n", type, &width, &height);
	fprintf(stderr, "%s -> %d, %d\n", type, width, height);
	prevlen = 0;
	repeat  = 1;
	while (height--)
	{
		linelen = 0;
		rle = 0;
		prevbit = 0;
		for (bitcount = 0; bitcount < width; bitcount++)
		{
			while ((bit = getchar()) != '0' && bit != '1')
				if (bit == EOF)
					break;
			if (bit == prevbit)
			{
				rle++;
			}
			else
			{
				if (rle)
					scanline[linelen++] = (prevbit == '0' ? 128 : 0) + rle;
				prevbit = bit;
				rle = 1;
			}
		}
		if (rle)
			scanline[linelen++] = (prevbit == '0' ? 128 : 0) + rle;
		if (linelen == prevlen && scancmp(scanline, prevline, linelen) == 0)
			repeat++;
		else
		{
			if (prevlen)
			{
				printf("\t!BYTE\t0,%d\t; Scanline repeat count\n", repeat);
				printf("\t!BYTE\t");
				for (bytecount = 0; bytecount < prevlen-1; bytecount++)
					printf("%s%d,", prevline[bytecount] & 0x80 ? "128+" : "", prevline[bytecount] & 0x7F);
				printf("%s%d\n", prevline[prevlen-1] & 0x80 ? "128+" : "", prevline[prevlen-1] & 0x7F);
			}
			for (bytecount = 0; bytecount < linelen; bytecount++)
				prevline[bytecount] = scanline[bytecount];
			prevlen = linelen;
			repeat = 1;
		}
	}
	if (linelen)
	{
		printf("\t!BYTE\t0,%d\t; Scanline repeat count\n", repeat);
		printf("\t!BYTE\t");
		for (bytecount = 0; bytecount < linelen-1; bytecount++)
			printf("%s%d,", scanline[bytecount] & 0x80 ? "128+" : "", scanline[bytecount] & 0x7F);
		printf("%s%d\n", scanline[linelen-1] & 0x80 ? "128+" : "", scanline[linelen-1] & 0x7F);
	}
	printf("\t!BYTE	0,0\t; End of compressed map\n");
	return 0;
}

/* Checksum and relocation utility for Mega-Bios
   Copyright (c) 2024, Sergio Aguayo

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its
     contributors may be used to endorse or promote products derived from
     this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


This is a very simple utility to calculate the checksum of the MegaBios.
It is very specific to our use case and we intend to keep it that way
because of the simplicity.

*/

#include <stdio.h>
#include <stdlib.h>

//#pragma pack(push, 1)
struct MZExe {
	unsigned short signature; /* == 0x5a4D */
	unsigned short bytes_in_last_block;
	unsigned short blocks_in_file;
	unsigned short num_relocs;
	unsigned short header_paragraphs;
	unsigned short min_extra_paragraphs;
	unsigned short max_extra_paragraphs;
	unsigned short ss;
	unsigned short sp;
	unsigned short checksum;
	unsigned short ip;
	unsigned short cs;
	unsigned short reloc_table_offset;
	unsigned short overlay_number;
};
struct EXE_RELOC {
  unsigned short offset;
  unsigned short segment;
};
//#pragma pack(pop, 1)

#define FILE_SIZE	8192
#define RELOC_SEGMENT	0xF000
#define CHECKSUM_OFFSET	0x1FE0

long getFileSize(FILE *fh) {
	long curPos, size;
   curPos = ftell(fh);
	fseek(fh, 0, SEEK_END);
	size = ftell(fh);
	fseek(fh, curPos, SEEK_SET);
	return size;
}

unsigned char calculateChecksum(unsigned char *data) {
	unsigned char checksum = 0;
   int i;
	for(i = 0; i < FILE_SIZE; i++) {
		checksum += data[i];
	}
	printf("Sum = %02X\n", checksum);
	checksum = 0-checksum;
	printf("Checksum = %02X\n", checksum);
	return checksum;
}

int main(int argc, char* argv[]) {
	FILE *inFile = NULL, *outFile = NULL;
	struct MZExe exeHdr;
	struct EXE_RELOC *relocs = NULL;
	long codeOffset;
	long fileSize;
	unsigned char *fileData = NULL;
   long skipCode;
   int i;

	if(argc != 3) {
		printf("Usage: %s inputFile outputFile\n", argv[0]);
		goto _errorExit;
	}
	inFile = fopen(argv[1], "rb");
	if(inFile == NULL) {
		printf("Cannot open input file: %s\n", argv[1]);
		goto _errorExit;
	}

	outFile = fopen(argv[2], "wb");
	if(outFile == NULL) {
		printf("Cannot open output file: %s\n", argv[2]);
		goto _errorExit;
	}

	if(fread(&exeHdr, sizeof(struct MZExe), 1, inFile) != 1) {
		printf("Cannot read EXE file header: %s\n", argv[1]);
		goto _errorExit;
	}

	if(exeHdr.signature != 0x5A4D) {
		printf("Invalid MZ EXE signature.\n");
		goto _errorExit;
	}

	relocs = malloc(exeHdr.num_relocs*sizeof(struct EXE_RELOC));
	if(relocs == NULL) {
		printf("Cannot allocate memory for relocation info.\n");
		goto _errorExit;
	}

	if(fseek(inFile, exeHdr.reloc_table_offset, SEEK_SET)) {
		printf("Error seeking for relocation table.\n");
		goto _errorExit;
	}

	if(fread(relocs, sizeof(struct EXE_RELOC), exeHdr.num_relocs, inFile) != exeHdr.num_relocs) {
		printf("Error reading relocations.\n");
		goto _errorExit;
	}


	codeOffset = exeHdr.header_paragraphs << 4;
	fileSize = getFileSize(inFile) - codeOffset;
   skipCode = fileSize - FILE_SIZE;

	fileData = malloc(skipCode);
	if(fileData == NULL) {
		printf("Cannot allocate memory to read file.\n");
		goto _errorExit;
	}

	if(fseek(inFile, codeOffset+skipCode, SEEK_SET)) {
		printf("Error seeking for code\n");
		goto _errorExit;
	}

	if(fread(fileData, FILE_SIZE, 1, inFile) != 1) {
		printf("Couldn't read input file.\n");
		goto _errorExit;
	}

	for(i = 0; i < exeHdr.num_relocs; i++) {
      unsigned short *target;
		struct EXE_RELOC *reloc = &relocs[i];
		unsigned int offset = ((unsigned int)reloc->segment << 4) + reloc->offset;
      if(offset < skipCode) {
      	printf("Relocation outside of last 8K boundary. Please check.\n");
         goto _errorExit;
      }
      offset -= skipCode;
		target = (unsigned short *)&fileData[offset];
		*target += RELOC_SEGMENT;
	}

	fileData[CHECKSUM_OFFSET] = 0;		// Should be zero from build, but just in case...
	fileData[CHECKSUM_OFFSET] = calculateChecksum(fileData);
	if(fwrite(fileData, FILE_SIZE, 1, outFile) != 1) {
		printf("Couldn't write output file.\n");
		goto _errorExit;
	}
	free(fileData);
	fclose(inFile);
	fclose(outFile);
	return 0;

_errorExit:
	if(relocs != NULL) {
		free(relocs);
		relocs = NULL;
	}

	if(fileData != NULL) {
		free(fileData);
		fileData = NULL;
	}
	if(inFile != NULL) {
		fclose(inFile);
		inFile = NULL;
	}
	if(outFile != NULL) {
		fclose(outFile);
		outFile = NULL;
	}
	
	return -1;
}

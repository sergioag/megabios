/* Checksum utility for Mega-Bios
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

#define FILE_SIZE	8192
#define CHECKSUM_OFFSET	0x1FE0

unsigned char calculateChecksum(unsigned char *data) {
	unsigned char checksum = 0;
	for(int i = 0; i < FILE_SIZE; i++) {
		checksum += data[i];
	}
	printf("Sum = %02X\n", checksum);
	checksum = 0-checksum;
	printf("Checksum = %02X\n", checksum);
	return checksum;
}

int main(int argc, char* argv[]) {
	FILE *inFile = NULL, *outFile = NULL;
	unsigned char *fileData = NULL;
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
	fileData = malloc(FILE_SIZE);
	if(fileData == NULL) {
		printf("Cannot allocate memory to read file.\n");
		goto _errorExit;
	}
	if(fread(fileData, FILE_SIZE, 1, inFile) != 1) {
		printf("Couldn't read input file.\n");
		goto _errorExit;
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

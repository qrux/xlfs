#define _XOPEN_SOURCE
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#define __USE_GNU
#include <crypt.h>

int main( int argc, char **argv ) {
	int i = 0;
	char *key = argv[1];
	char *salt = argv[2];
	char fullsalt[20];
	struct crypt_data cdata;
	struct crypt_data *pcdata;
	char *enc = (char *)0;

	pcdata = &cdata;

	if ( 3 > argc ) {
		fprintf(stderr, "Usage: %s <key> <salt>\n", argv[0]);
		return 1;
	}

	//for ( i = 0; i < argc; ++i ) {
		//printf("  arg [%d]: %s\n", i, argv[i]);
	//}

	pcdata->initialized = 0;

	memcpy(fullsalt,   "$6$", 3);
	memcpy(fullsalt+3, salt, 16);
	fullsalt[19] = 0;

	//printf("    full salt: %s\n", fullsalt);

	enc = crypt_r(key, fullsalt, pcdata);

	//printf("  Encrypted passwd: %s\n", enc);
	printf("%s\n", enc);
	
	return 0;
}

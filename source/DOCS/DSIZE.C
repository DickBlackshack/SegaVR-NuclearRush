#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void
main(int	argc,char *argv[])
{
	FILE				*infile;
	char				line[256];
	char				name[256];
	char				newsym[256];
	int				i;
	char				*ptr;
	int				done;
	long				addr;
	long				size;
	long				last;
	long				first;

	if (argc != 2) {
		printf("Usage: DSIZE file\n");
		exit(0);
	}
	infile = fopen(argv[1],"r");
	fgets(line,256,infile);
	sscanf(line,"%s |%lx",name,&last);
	do {
		fgets(line,256,infile);
		sscanf(line,"%s |%lx",newsym,&addr);
		printf("%s\t%08ld\n",name,addr-last);
		strcpy(name,newsym);
		last = addr;
	} while (!feof(infile));
	fclose(infile);
}


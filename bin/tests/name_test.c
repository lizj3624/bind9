/*
 * Copyright (C) 1998, 1999  Internet Software Consortium.
 * 
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM DISCLAIMS
 * ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL INTERNET SOFTWARE
 * CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 */

#include <config.h>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <isc/assertions.h>
#include <isc/boolean.h>
#include <isc/region.h>

#include <dns/types.h>
#include <dns/result.h>
#include <dns/name.h>
#include <dns/fixedname.h>

static void
print_wirename(isc_region_t *name) {
	unsigned char *ccurr, *cend;
		
	ccurr = name->base;
	cend = ccurr + name->length;
	while (ccurr != cend)
		printf("%02x ", *ccurr++);
	printf("\n");
}

int
main(int argc, char *argv[]) {
	char s[1000];
	dns_result_t result;
	dns_fixedname_t wname, oname, compname;
	isc_buffer_t source;
	isc_region_t r;
	dns_name_t *name, *origin, *comp;
	isc_boolean_t downcase = ISC_FALSE;
	size_t len;
	isc_boolean_t quiet = ISC_FALSE;
	int ch;

	while ((ch = getopt(argc, argv, "q")) != -1) {
		switch (ch) {
		case 'q':
			quiet = ISC_TRUE;
			break;
		}
	}

	argc -= optind;
	argv += optind;

	if (argc > 0) {
		if (strcasecmp("none", argv[0]) == 0)
			origin = NULL;
		else {
			len = strlen(argv[0]);
			isc_buffer_init(&source, argv[0], len,
					ISC_BUFFERTYPE_TEXT);
			isc_buffer_add(&source, len);
			dns_fixedname_init(&oname);
			origin = &oname.name;
			result = dns_name_fromtext(origin, &source,
						   dns_rootname, ISC_FALSE,
						   NULL);
			if (result != 0) {
				fprintf(stderr,
					"dns_name_fromtext() failed: %d\n",
					result);
				exit(1);
			}
		}
	} else
		origin = dns_rootname;

	if (argc > 1) {
		if (strcasecmp("none", argv[1]) == 0)
			comp = NULL;
		else {
			len = strlen(argv[1]);
			isc_buffer_init(&source, argv[1], len,
					ISC_BUFFERTYPE_TEXT);
			isc_buffer_add(&source, len);
			dns_fixedname_init(&compname);
			comp = &compname.name;
			result = dns_name_fromtext(comp, &source,
						   origin, ISC_FALSE, NULL);
			if (result != 0) {
				fprintf(stderr,
					"dns_name_fromtext() failed: %d\n",
					result);
				exit(1);
			}
		}
	} else
		comp = NULL;

	dns_fixedname_init(&wname);
	name = &wname.name;
	while (gets(s) != NULL) {
		len = strlen(s);
		isc_buffer_init(&source, s, len, ISC_BUFFERTYPE_TEXT);
		isc_buffer_add(&source, len);
		result = dns_name_fromtext(name, &source, origin, downcase,
					   NULL);
		if (result == DNS_R_SUCCESS) {
			dns_name_toregion(name, &r);
			if (!quiet) {
				print_wirename(&r);
				printf("%u labels, %u bytes.\n",
				       dns_name_countlabels(name),
				       r.length);
			}
		} else
			printf("%s\n", dns_result_totext(result));

		if (result == DNS_R_SUCCESS) {
			isc_buffer_init(&source, s, sizeof s,
					ISC_BUFFERTYPE_TEXT);
			result = dns_name_totext(name, ISC_FALSE, &source);
			if (result == DNS_R_SUCCESS) {
				isc_buffer_used(&source, &r);
				printf("%.*s\n", (int)r.length, r.base);
				if (!quiet) {
					printf("%u bytes.\n", source.used);
				}
			} else
				printf("%s\n", dns_result_totext(result));
		}

		if (comp != NULL) {
			int order;
			unsigned int nlabels, nbits;
			dns_namereln_t namereln;

			namereln = dns_name_fullcompare(name, comp, &order,
							&nlabels, &nbits);
			if (!quiet) {
				if (order < 0)
					printf("<");
				else if (order > 0)
					printf(">");
				else
					printf("=");
				switch (namereln) {
				case dns_namereln_contains:
					printf(", contains");
					break;
				case dns_namereln_subdomain:
					printf(", subdomain");
					break;
				case dns_namereln_commonancestor:
					printf(", common ancestor");
					break;
				default:
					break;
				}
				if (namereln != dns_namereln_none &&
				    namereln != dns_namereln_equal)
					printf(", nlabels = %u, nbits = %u",
					       nlabels, nbits);
				printf("\n");
			}
		}
	}
	
	return (0);
}

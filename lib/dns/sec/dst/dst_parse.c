/*
 * Portions Copyright (c) 1995-1999 by Network Associates, Inc.
 *
 * Permission to use, copy modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND NETWORK ASSOCIATES
 * DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.  IN NO EVENT SHALL
 * NETWORK ASSOCIATES BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
 * FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
 * WITH THE USE OR PERFORMANCE OF THE SOFTWARE.
 */

/*
 * Principal Author: Brian Wellington
 * $Id: dst_parse.c,v 1.1 1999/07/12 20:08:29 bwelling Exp $
 */

#include <config.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#include <isc/assertions.h>
#include <isc/base64.h>
#include <isc/buffer.h>
#include <isc/int.h>
#include <isc/lex.h>
#include <isc/mem.h>
#include <isc/region.h>
#include <dns/rdata.h>

/* For chmod.  This should be removed. */
#include <sys/stat.h>

#include "dst_internal.h"
#include "dst_parse.h"
#include "dst/result.h"


#define PRIVATE_KEY_STR "Private-key-format:"
#define ALGORITHM_STR "Algorithm:"
#define RSA_STR "RSA"
#define DSA_STR "DSA"
#define HMAC_MD5_STR "HMAC_MD5"

struct parse_map {
	int value;
	char *tag;
};

static struct parse_map map[] = {
	{TAG_RSA_MODULUS, "Modulus:"},
	{TAG_RSA_PUBLICEXPONENT, "PublicExponent:"},
	{TAG_RSA_PRIVATEEXPONENT, "PrivateExponent:"},
	{TAG_RSA_PRIME1, "Prime1:"},
	{TAG_RSA_PRIME2, "Prime2:"},
	{TAG_RSA_EXPONENT1, "Exponent1:"},
	{TAG_RSA_EXPONENT2, "Exponent2:"},
	{TAG_RSA_COEFFICIENT, "Coefficient:"},

	{TAG_DSA_PRIME, "Prime(p):"},
	{TAG_DSA_SUBPRIME, "Subprime(q):"},
	{TAG_DSA_BASE, "Base(g):"},
	{TAG_DSA_PRIVATE, "Private_value(x):"},
	{TAG_DSA_PUBLIC, "Public_value(y):"},

	{TAG_HMACMD5_KEY, "Key:"},
	{0, NULL}
};

static int
find_value(const char *s) {
	int i;

	for (i = 0; ; i++) {
		if (map[i].tag == NULL)
			return (-1);
		else if (strcasecmp(s, map[i].tag) == 0)
			return (map[i].value);
	}
}

static char *
find_tag(const int value) {
	int i;

	for (i = 0; ; i++) {
		if (map[i].tag == NULL)
			return (NULL);
		else if (value == map[i].value)
			return (map[i].tag);
	}
}

static int
check_rsa(const dst_private_t *priv) {
	int i, j;
	if (priv->nelements != RSA_NTAGS)
		return (-1);
	for (i = 0; i < RSA_NTAGS; i++) {
		for (j = 0; j < priv->nelements; j++)
			if (priv->elements[j].tag == TAG(DST_ALG_RSA, i))
				break;
		if (j == priv->nelements)
			return (-1);
	}
	return (0);
}

static int
check_dsa(const dst_private_t *priv) {
	int i, j;
	if (priv->nelements != DSA_NTAGS)
		return (-1);
	for (i = 0; i < DSA_NTAGS; i++) {
		for (j = 0; j < priv->nelements; j++)
			if (priv->elements[j].tag == TAG(DST_ALG_DSA, i))
				break;
		if (j == priv->nelements)
			return (-1);
	}
	return (0);
}

static int
check_hmac_md5(const dst_private_t *priv) {
	if (priv->nelements != HMACMD5_NTAGS)
		return (-1);
	if (priv->elements[0].tag != TAG_HMACMD5_KEY)
		return (-1);
	return (0);
}

static int
check_data(const dst_private_t *priv, const int alg) {
	switch (alg) {
		case DST_ALG_RSA:
			return (check_rsa(priv));
		case DST_ALG_DSA:
			return (check_dsa(priv));
		case DST_ALG_HMAC_MD5:
			return (check_hmac_md5(priv));
		default:
			return (DST_R_UNSUPPORTED_ALG);
	}
}

void
dst_s_free_private_structure_fields(dst_private_t *priv, isc_mem_t *mctx) {
	int i;

	if (priv == NULL)
		return;
	for (i = 0; i < priv->nelements; i++) {
		if (priv->elements[i].data == NULL)
			continue;
		memset(priv->elements[i].data, 0, MAXFIELDSIZE);
		isc_mem_put(mctx, priv->elements[i].data, MAXFIELDSIZE);
	}
	priv->nelements = 0;
}

int
dst_s_parse_private_key_file(const char *name, const int alg, const int id,
			     dst_private_t *priv, isc_mem_t *mctx)
{
	char filename[PATH_MAX];
	int n = 0, ret, major, minor;
	isc_buffer_t b;
	isc_lex_t *lex = NULL;
	isc_token_t token;
	unsigned int opt = ISC_LEXOPT_EOL;
	isc_result_t iret;
	isc_result_t error = DST_R_INVALID_PRIVATE_KEY;

	REQUIRE(priv != NULL);

	priv->nelements = 0;

	ret = dst_s_build_filename(filename, name, id, alg, PRIVATE_KEY,
				   PATH_MAX);
	if (ret < 0)
		return (DST_R_NAME_TOO_LONG);

	iret = isc_lex_create(mctx, 256, &lex);
	if (iret != ISC_R_SUCCESS)
		return (DST_R_NOMEMORY);

	iret = isc_lex_openfile(lex, filename);
	if (iret != ISC_R_SUCCESS)
		goto fail;

#define NEXTTOKEN(lex, opt, token) \
	{ \
		iret = isc_lex_gettoken(lex, opt, token); \
		if (iret != ISC_R_SUCCESS) \
			goto fail; \
	}

#define READLINE(lex, opt, token) \
	do { \
		NEXTTOKEN(lex, opt, token) \
	} while ((*token).type != isc_tokentype_eol) \

	/* Read the description line */
	NEXTTOKEN(lex, opt, &token);
	if (token.type != isc_tokentype_string ||
	    strcmp(token.value.as_pointer, PRIVATE_KEY_STR) != 0)
		goto fail;
	
	NEXTTOKEN(lex, opt, &token);
	if (token.type != isc_tokentype_string ||
	    ((char *)token.value.as_pointer)[0] != 'v')
		goto fail;
	if (sscanf(token.value.as_pointer, "v%d.%d", &major, &minor) != 2)
		goto fail;

	if (major > MAJOR_VERSION ||
	    (major == MAJOR_VERSION && minor > MINOR_VERSION))
		goto fail;

	READLINE(lex, opt, &token);

	/* Read the algorithm line */
	NEXTTOKEN(lex, opt, &token);
	if (token.type != isc_tokentype_string ||
	    strcmp(token.value.as_pointer, ALGORITHM_STR) != 0)
		goto fail;

	NEXTTOKEN(lex, opt | ISC_LEXOPT_NUMBER, &token);
	if (token.type != isc_tokentype_number ||
	    token.value.as_ulong != (unsigned long) alg)
		goto fail;

	READLINE(lex, opt, &token);

	/* Read the key data */
	for (n = 0; n < MAXFIELDS; n++) {
		int tag;
		unsigned char *data;
		isc_region_t r;

		iret = isc_lex_gettoken(lex, opt, &token); 
		if (iret == ISC_R_EOF)
			break;
		if (iret != ISC_R_SUCCESS)
			goto fail;
		if (token.type != isc_tokentype_string)
			goto fail;

		memset(&priv->elements[n], 0, sizeof(dst_private_element_t));
		tag = find_value(token.value.as_pointer);
		if (tag < 0 || TAG_ALG(tag) != alg)
			goto fail;
		priv->elements[n].tag = tag;

		data = (unsigned char *) isc_mem_get(mctx, MAXFIELDSIZE);
		if (data == NULL) {
			error = DST_R_INVALID_PRIVATE_KEY;
			goto fail;
		}
		isc_buffer_init(&b, data, MAXFIELDSIZE, ISC_BUFFERTYPE_BINARY);
		ret = isc_base64_tobuffer(lex, &b, -1);
		if (ret != ISC_R_SUCCESS)
			goto fail;
		isc_buffer_used(&b, &r);
		priv->elements[n].length = r.length;
		priv->elements[n].data = r.base;

		READLINE(lex, opt, &token);
	}

	priv->nelements = n;

	if (check_data(priv, alg) < 0)
		goto fail;

	isc_lex_close(lex);
	isc_lex_destroy(&lex);

	return (DST_R_SUCCESS);

fail:
	if (lex != NULL) {
		isc_lex_close(lex);
		isc_lex_destroy(&lex);
	}

	priv->nelements = n;
	dst_s_free_private_structure_fields(priv, mctx);
	return (DST_R_INVALID_PRIVATE_KEY);
}

int
dst_s_write_private_key_file(const char *name, const int alg, const int id,
			     const dst_private_t *priv)
{
	FILE *fp;
	int ret, i;
	isc_result_t iret;
	char filename[PATH_MAX];
	char buffer[MAXFIELDSIZE * 2];

	REQUIRE(priv != NULL);

	if (check_data(priv, alg) < 0)
		return (DST_R_INVALID_PRIVATE_KEY);

	ret = dst_s_build_filename(filename, name, id, alg, PRIVATE_KEY,
				   PATH_MAX);
	if (ret < 0)
		return (DST_R_NAME_TOO_LONG);

	if ((fp = fopen(filename, "w")) == NULL)
		return (DST_R_WRITE_ERROR);

	/* This won't exist on non-unix systems.  Hmmm.... */
	chmod(filename, 0600);

	fprintf(fp, "%s v%d.%d\n", PRIVATE_KEY_STR, MAJOR_VERSION,
		MINOR_VERSION);

	fprintf(fp, "%s %d ", ALGORITHM_STR, alg);
	switch (alg) {
		case DST_ALG_RSA: fprintf(fp, "(RSA)\n"); break;
		case DST_ALG_DSA: fprintf(fp, "(DSA)\n"); break;
		case DST_ALG_HMAC_MD5: fprintf(fp, "(HMAC_MD5)\n"); break;
		default : fprintf(fp, "(?)\n"); break;
	}

	for (i = 0; i < priv->nelements; i++) {
		isc_buffer_t b;
		isc_region_t r;
		char *s;

		s = find_tag(priv->elements[i].tag);

		r.base = priv->elements[i].data;
		r.length = priv->elements[i].length;
		isc_buffer_init(&b, buffer, sizeof(buffer),
				ISC_BUFFERTYPE_TEXT);
		iret = isc_base64_totext(&r, sizeof(buffer), "", &b);
		if (iret != ISC_R_SUCCESS) {
			fclose(fp);
			return(DST_R_INVALID_PRIVATE_KEY);
		}
		isc_buffer_used(&b, &r);

		fprintf(fp, "%s ", s);
		fwrite(r.base, 1, r.length, fp);
		fprintf(fp, "\n");
	}
	
	fclose(fp);
	return (DST_R_SUCCESS);
}

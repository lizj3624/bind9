/*
 * Copyright (C) 2000  Internet Software Consortium.
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

/* $Id: sha1.h,v 1.4 2000/06/07 02:28:43 bwelling Exp $ */

/*	$NetBSD: sha1.h,v 1.2 1998/05/29 22:55:44 thorpej Exp $	*/

/*
 * SHA-1 in C
 * By Steve Reid <steve@edmweb.com>
 * 100% Public Domain
 */

#ifndef ISC_SHA1_H
#define	ISC_SHA1_H

#include <isc/types.h>

#define ISC_SHA1_DIGESTLENGTH 20

typedef struct {
	isc_uint32_t state[5];
	isc_uint32_t count[2];  
	unsigned char buffer[64];
} isc_sha1_t;
  
void isc_sha1_init(isc_sha1_t *ctx);
void isc_sha1_invalidate(isc_sha1_t *ctx);
void isc_sha1_update(isc_sha1_t *ctx, const unsigned char *data,
		     unsigned int len);
void isc_sha1_final(isc_sha1_t *ctx, unsigned char *digest);

#endif /* ISC_SHA1_H */

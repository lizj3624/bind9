/*
 * Copyright (C) 1999-2001, 2004, 2005, 2007, 2016  Internet Systems Consortium, Inc. ("ISC")
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

/* $Id: serial.c,v 1.12 2007/06/19 23:47:17 tbox Exp $ */

/*! \file */

#include <config.h>

#include <isc/serial.h>

isc_boolean_t
isc_serial_lt(isc_uint32_t a, isc_uint32_t b) {
	/*
	 * Undefined => ISC_FALSE
	 */
	if (a == (b ^ 0x80000000U))
		return (ISC_FALSE);
	return (((isc_int32_t)(a - b) < 0) ? ISC_TRUE : ISC_FALSE);
}

isc_boolean_t
isc_serial_gt(isc_uint32_t a, isc_uint32_t b) {
	return (((isc_int32_t)(a - b) > 0) ? ISC_TRUE : ISC_FALSE);
}

isc_boolean_t
isc_serial_le(isc_uint32_t a, isc_uint32_t b) {
	return ((a == b) ? ISC_TRUE : isc_serial_lt(a, b));
}

isc_boolean_t
isc_serial_ge(isc_uint32_t a, isc_uint32_t b) {
	return ((a == b) ? ISC_TRUE : isc_serial_gt(a, b));
}

isc_boolean_t
isc_serial_eq(isc_uint32_t a, isc_uint32_t b) {
	return ((a == b) ? ISC_TRUE : ISC_FALSE);
}

isc_boolean_t
isc_serial_ne(isc_uint32_t a, isc_uint32_t b) {
	return ((a != b) ? ISC_TRUE : ISC_FALSE);
}

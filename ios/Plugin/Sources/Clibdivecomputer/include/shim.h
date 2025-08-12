//
//  shim.h
//  BLETest
//
//  Created by User on 24/12/2024.
//

#ifndef LIBDC_SHIM_H
#define LIBDC_SHIM_H

// Use absolute paths with SRCROOT
#include <libdivecomputer/common.h>
#include <libdivecomputer/context.h>
#include <libdivecomputer/descriptor.h>
#include <libdivecomputer/device.h>
#include <libdivecomputer/parser.h>
#include <libdivecomputer/iostream.h>
#include <libdivecomputer/custom.h>
#include <libdivecomputer/array.h>

dc_status_t dc_parser_new2(dc_parser_t **parser, dc_context_t *context, dc_descriptor_t *descriptor, const unsigned char *data, size_t size);
dc_descriptor_t *dc_descriptor_get(dc_family_t family, unsigned int model);

#endif /* LIBDC_SHIM_H */
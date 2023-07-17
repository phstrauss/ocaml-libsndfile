/* Stub code to access libsndfile functions from OCaml */

/*
**	Copyright (c) 2006, 2007 Erik de Castro Lopo <erikd at mega-nerd dot com>
**	WWW: http://www.mega-nerd.com/libsndfile/Ocaml/
**
**  Maintainer : Philippe Strauss <philippe@strauss-acoustics.ch>
**
**	This library is free software; you can redistribute it and/or
**	modify it under the terms of the GNU Lesser General Public
**	License as published by the Free Software Foundation; either
**	version 2 of the License, or (at your option) any later version.
**
**	This library is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
**	Lesser General Public License for more details.
**
**	You should have received a copy of the GNU Lesser General Public
**	License along with this library; if not, write to the Free Software
**	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/bigarray.h>

#include <stdlib.h>
#include <string.h>

#include <sndfile.h>

#define CAML_SNDFILE_VERSION "v1.1"

#define ARRAY_LEN(x)	((int) (sizeof (x) / sizeof (x [0])))

typedef struct
{	SNDFILE * file ;
	SF_INFO info ;
} SF_WRAPPER ;


static void caml_sf_finalize (value file) ;
static int caml_val_to_major_format (int f) ;
static int caml_val_to_minor_format (int f) ;

static struct custom_operations sndfile_custom_ops =
{
	/* identifier */ "SNDFILE/CAMLinterface/" CAML_SNDFILE_VERSION "/sndfile",
	/* finalize */ caml_sf_finalize,
	/* compare */ NULL,
	/* hash */ NULL,
	/* serialize */ NULL,
	/* deserialize */ NULL,
	/* compare_ext */ NULL
} ;

value
caml_sf_format_e (value v_major, value v_minor, value v_endian)
{
	int minor, major, endian ;

	CAMLparam3 (v_major, v_minor, v_endian) ;

	minor = caml_val_to_minor_format (Int_val (v_minor)) ;
	major = caml_val_to_major_format (Int_val (v_major)) ;
	endian = (Int_val (v_endian) << 28) & SF_FORMAT_ENDMASK ;

	CAMLreturn (Val_int (endian + major + minor)) ;
} /* caml_sf_format_e */

value
caml_sf_open_private (value v_filename, value v_mode, value v_fmt, value v_channels, value v_samplerate)
{
	value v_wrapper ;
	SF_WRAPPER *wrapper ;
	int mode = 0 ;

	CAMLparam5 (v_filename, v_mode, v_fmt, v_channels, v_samplerate) ;

	v_wrapper = caml_alloc_custom (&sndfile_custom_ops, sizeof (SF_WRAPPER), sizeof (SF_WRAPPER), sizeof (SF_WRAPPER)) ;
	wrapper = Data_custom_val (v_wrapper) ;
	if (wrapper == NULL)
		caml_failwith ("Sndfile.sf_open : caml_alloc_custom failed.") ;

	memset (wrapper, 0, sizeof (*wrapper)) ;

	switch (Int_val (v_mode))
	{	case 0 :
			mode = SFM_READ ;
			break ;
		case 1 :
			mode = SFM_WRITE ;
			wrapper->info.format = Int_val (v_fmt) ;
			wrapper->info.channels = Int_val (v_channels) ;
			wrapper->info.samplerate = Int_val (v_samplerate) ;
			break ;
		case 2 :
			mode = SFM_RDWR ;
			wrapper->info.format = Int_val (v_fmt) ;
			wrapper->info.channels = Int_val (v_channels) ;
			wrapper->info.samplerate = Int_val (v_samplerate) ;
			break ;
		default :
			break ;
		} ;

	wrapper->file = sf_open (String_val (v_filename), mode, &wrapper->info) ;

	if (wrapper->file == NULL)
	{	int errnum = sf_error (NULL) ;
		const char *err_str = sf_error_number (errnum) ;

		if (err_str == NULL)
			err_str = "????" ;

		value sferr = caml_alloc_tuple (2) ;
		
		switch (errnum)
		{	case SF_ERR_NO_ERROR :
			case SF_ERR_UNRECOGNISED_FORMAT	:
			case SF_ERR_SYSTEM :
			case SF_ERR_MALFORMED_FILE :
			case SF_ERR_UNSUPPORTED_ENCODING :
				break ;
			default :
				errnum = SF_ERR_UNSUPPORTED_ENCODING + 1 ;
				break ;
			} ;

		Store_field (sferr, 0, caml_copy_nativeint (errnum)) ;
		Store_field (sferr, 1, caml_copy_string (err_str)) ;

		value *exn = caml_named_value ("sndfile_open_exn") ;
		if (exn == NULL)
			caml_failwith ("Uninspired should never happen failure: asdasdasdas") ;

		caml_raise_with_arg (*exn, sferr) ;
		} ;

    CAMLreturn (v_wrapper) ;
} /* caml_sf_open_private */

value
caml_sf_close (value v_wrapper)
{
	SF_WRAPPER *wrapper ;

	CAMLparam1 (v_wrapper) ;
	wrapper = Data_custom_val (v_wrapper) ;

	if (wrapper->file != NULL)
	{	sf_close (wrapper->file) ;
		wrapper->file = NULL ;
		} ;

    CAMLreturn (Val_unit) ;
} /* caml_sf_close */

/* Pulled from ocaml-cairo sources. Not sure how portable/reliable this is. */
#define Double_array_val(v)    ((double *)(v))
#define Double_array_length(v) (Wosize_val(v) / Double_wosize)

value
caml_sf_read (value v_wrapper, value v_data)
{
	SF_WRAPPER *wrapper ;
	int count ;

	CAMLparam2 (v_wrapper, v_data) ;
	wrapper = Data_custom_val (v_wrapper) ;
	
	count = sf_read_double (wrapper->file, Double_array_val (v_data), Double_array_length (v_data)) ;

    CAMLreturn (Val_int (count)) ;
} /* caml_sf_read */

value
caml_sf_write (value v_wrapper, value v_data, value v_count)
{
	SF_WRAPPER *wrapper ;
	int count ;
	int wrote ;

	CAMLparam3 (v_wrapper, v_data, v_count) ;
	wrapper = Data_custom_val (v_wrapper) ;

	count = Int_val(v_count) ;

	/* wrote = sf_write_double (wrapper->file, Double_array_val (v_data), Double_array_length (v_data)) ; */
	/* Ph. Strauss : pass v_count as third arg, for last/short write */
	wrote = sf_write_double (wrapper->file, Double_array_val (v_data), count) ;

    CAMLreturn (Val_int (wrote)) ;
} /* caml_sf_write */

value
caml_sf_frames (value v_wrapper)
{
	SF_WRAPPER *wrapper ;
	sf_count_t frames = 0 ;

	CAMLparam1 (v_wrapper) ;
	wrapper = Data_custom_val (v_wrapper) ;

	if (wrapper->file != NULL)
		frames = wrapper->info.frames ;

	CAMLreturn (caml_copy_int64 (frames)) ;
} /* caml_sf_frames */

value
caml_sf_samplerate (value v_wrapper)
{
	SF_WRAPPER *wrapper ;
	int samplerate = 0 ;

	CAMLparam1 (v_wrapper) ;
	wrapper = Data_custom_val (v_wrapper) ;

	if (wrapper->file != NULL)
		samplerate = wrapper->info.samplerate ;

	CAMLreturn (Val_int (samplerate)) ;
} /* caml_sf_samplerate */

value
caml_sf_channels (value v_wrapper)
{
	SF_WRAPPER *wrapper ;
	int channels = 0 ;

	CAMLparam1 (v_wrapper) ;
	wrapper = Data_custom_val (v_wrapper) ;

	if (wrapper->file != NULL)
		channels = wrapper->info.channels ;

	CAMLreturn (Val_int (channels)) ;
} /* caml_sf_channels */

value
caml_sf_seek (value v_wrapper, value v_pos, value v_mode)
{
	SF_WRAPPER *wrapper ;
	sf_count_t pos ;
	sf_count_t offset ;
	int mode ;

	CAMLparam3 (v_wrapper, v_pos, v_mode) ;

	wrapper = Data_custom_val (v_wrapper) ;
	mode = Int_val (v_mode) ;
	pos = Int64_val (v_pos) ;

	offset = sf_seek (wrapper->file, pos, mode) ;

	/* 2012-11-24, bugfix by Ph. Strauss, was sigsegv here */
	CAMLreturn (caml_copy_int64 (offset)) ;
} /* caml_sf_seek */

value
caml_sf_compare (value v_wrapper1, value v_wrapper2)
{
	SF_WRAPPER *wrapper1, *wrapper2 ;

	CAMLparam2 (v_wrapper1, v_wrapper2) ;

	wrapper1 = Data_custom_val (v_wrapper1) ;
	wrapper2 = Data_custom_val (v_wrapper2) ;

	CAMLreturn (Val_int (wrapper2 - wrapper1)) ;
} /* caml_sf_compare */

/*==============================================================================
*/

static void
caml_sf_finalize (value v_wrapper)
{
	SF_WRAPPER *wrapper ;

	wrapper = Data_custom_val (v_wrapper) ;

	if (wrapper->file != NULL)
	{	sf_close (wrapper->file) ;
		wrapper->file = NULL ;
		} ;
	
} /* caml_sf_finalize */


static int
caml_val_to_major_format (int f)
{	static int format [] =
	{	0,
		0x010000,	/* SF_FORMAT_WAV */
		0x020000,	/* SF_FORMAT_AIFF */
		0x030000,	/* SF_FORMAT_AU */
		0x040000,	/* SF_FORMAT_RAW */
		0x050000,	/* SF_FORMAT_PAF */
		0x060000,	/* SF_FORMAT_SVX */
		0x070000,	/* SF_FORMAT_NIST */
		0x080000,	/* SF_FORMAT_VOC */
		0x0A0000,	/* SF_FORMAT_IRCAM */
		0x0B0000,	/* SF_FORMAT_W64 */
		0x0C0000,	/* SF_FORMAT_MAT4 */
		0x0D0000,	/* SF_FORMAT_MAT5 */
		0x0E0000,	/* SF_FORMAT_PVF */
		0x0F0000,	/* SF_FORMAT_XI */
		0x100000,	/* SF_FORMAT_HTK */
		0x110000,	/* SF_FORMAT_SDS */
		0x120000,	/* SF_FORMAT_AVR */
		0x130000,	/* SF_FORMAT_WAVEX */
		0x160000,	/* SF_FORMAT_SD2 */
		0x170000,	/* SF_FORMAT_FLAC */
		0x180000	/* SF_FORMAT_CAF */
		} ;

	if (f < 0 || f >= ARRAY_LEN (format))
		return 0 ;
	
	return format [f] ;
} /* caml_val_to_major_format */

static int
caml_val_to_minor_format (int f)
{	static int format [] =
	{	0,
		0x0001, /* SF_FORMAT_PCM_S8 */
		0x0002, /* SF_FORMAT_PCM_16 */
		0x0003, /* SF_FORMAT_PCM_24 */
		0x0004, /* SF_FORMAT_PCM_32 */
		0x0005, /* SF_FORMAT_PCM_U8 */
		0x0006, /* SF_FORMAT_FLOAT */
		0x0007, /* SF_FORMAT_DOUBLE */
		0x0010, /* SF_FORMAT_ULAW */
		0x0011, /* SF_FORMAT_ALAW */
		0x0012, /* SF_FORMAT_IMA_ADPCM */
		0x0013, /* SF_FORMAT_MS_ADPCM */
		0x0020, /* SF_FORMAT_GSM610 */
		0x0021, /* SF_FORMAT_VOX_ADPCM */
		0x0030, /* SF_FORMAT_G721_32 */
		0x0031, /* SF_FORMAT_G723_24 */
		0x0032, /* SF_FORMAT_G723_40 */
		0x0040, /* SF_FORMAT_DWVW_12 */
		0x0041, /* SF_FORMAT_DWVW_16 */
		0x0042, /* SF_FORMAT_DWVW_24 */
		0x0043, /* SF_FORMAT_DWVW_N */
		0x0050, /* SF_FORMAT_DPCM_8 */
		0x0051, /* SF_FORMAT_DPCM_16 */
		} ;

	if (f < 0 || f >= ARRAY_LEN (format))
		return 0 ;
	
	return format [f] ;
} /* caml_val_to_minor_format */

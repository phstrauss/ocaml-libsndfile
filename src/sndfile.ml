(*
** File: sndfile.ml
**
**	Copyright (c) 2006, 2007 Erik de Castro Lopo <erikd at mega-nerd dot com>
**	WWW: http://www.mega-nerd.com/libsndfile/Ocaml/
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
*)

type open_mode_t =
	|	READ
	|	WRITE
	|	RDWR

type seek_mode_t =
	|	SEEK_SET
	|	SEEK_CUR
	|	SEEL_END

type major_format_t =
	|	MAJOR_NONE
	|	MAJOR_WAV
	|	MAJOR_AIFF
	|	MAJOR_AU
	|	MAJOR_RAW
	|	MAJOR_PAF
	|	MAJOR_SVX
	|	MAJOR_NIST
	|	MAJOR_VOC
	|	MAJOR_IRCAM
	|	MAJOR_W64
	|	MAJOR_MAT4
	|	MAJOR_MAT5
	|	MAJOR_PVF
	|	MAJOR_XI
	|	MAJOR_HTK
	|	MAJOR_SDS
	|	MAJOR_AVR
	|	MAJOR_WAVEX
	|	MAJOR_SD2
	|	MAJOR_FLAC
	|	MAJOR_CAF

type minor_format_t =
	|	MINOR_NONE
	|	MINOR_PCM_S8
	|	MINOR_PCM_16
	|	MINOR_PCM_24
	|	MINOR_PCM_32
	|	MINOR_PCM_U8
	|	MINOR_FLOAT
	|	MINOR_DOUBLE
	|	MINOR_ULAW
	|	MINOR_ALAW
	|	MINOR_IMA_ADPCM
	|	MINOR_MS_ADPCM
	|	MINOR_GSM610
	|	MINOR_VOX_ADPCM
	|	MINOR_G721_32
	|	MINOR_G723_24
	|	MINOR_G723_40
	|	MINOR_DWVW_12
	|	MINOR_DWVW_16
	|	MINOR_DWVW_24
	|	MINOR_DWVW_N
	|	MINOR_DPCM_8
	|	MINOR_DPCM_16

type endianness_t =
	|	ENDIAN_FILE
	|	ENDIAN_LITTLE
	|	ENDIAN_BIG
	|	ENDIAN_CPU


type file_format_t

type error =
	|	No_error
	|	Unrecognised_format
	|	System
	|	Malformed_file
	|	Unsupported_encoding
	|	Internal
  
exception Error of (error * string)

type t

external format_e : major_format_t -> minor_format_t -> endianness_t -> file_format_t = "caml_sf_format_e"

let format major minor =
	format_e major minor ENDIAN_FILE

external open_private :
	string -> (* filename *)
	open_mode_t ->
	file_format_t ->
	int -> (* channels *)
	int -> (* samplerate *)
	t = "caml_sf_open_private"

let bad_format = format MAJOR_NONE MINOR_NONE

let openfile ?(info = (READ, bad_format, 0, 0)) filename =
	let (mode, fmt, channels, samplerate) = info in
	open_private filename mode fmt channels samplerate

external close : t -> unit = "caml_sf_close"

external read : t -> float array -> int = "caml_sf_read"
external write : t -> float array -> int -> int = "caml_sf_write"


external frames : t -> Int64.t = "caml_sf_frames"

external samplerate : t -> int = "caml_sf_samplerate"

external channels : t -> int = "caml_sf_channels"

external seek : t -> Int64.t -> seek_mode_t -> Int64.t = "caml_sf_seek"

external compare : t -> t -> int = "caml_sf_compare"

let _ =
	Callback.register_exception "sndfile_open_exn" (Error (No_error, "No error."))

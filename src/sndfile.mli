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

(** libsndfile interface for OCaml.

	libsndfile (http://www.mega-nerd.com/libsndfile) is a library for reading
	and writing a huge number of different audio file formats.

	Typical (simple) usage for small files:

{[
	let file = Sndfile.openfile filename in
	let frames = Int64.to_int (Sndfile.frames file) in
	let data = Array.create frames 0.0 in
	let readcount = Sndfile.read file data in
	.....
]}

*)

type open_mode_t =
	|	READ			(** Open file for read. *)
	|	WRITE			(** Open file for write. *)
	|	RDWR			(** Open file for read/write. *)

type seek_mode_t =
	|	SEEK_SET			(** Seek relative to start of file. *)
	|	SEEK_CUR			(** Seek relative to current position. *)
	|	SEEL_END			(** Seek relative to end of file. *)

type major_format_t =
	|	MAJOR_NONE
	|	MAJOR_WAV		(** Microsoft WAV format (little endian default). *)
	|	MAJOR_AIFF		(** Apple/SGI AIFF format (big endian). *)
	|	MAJOR_AU			(** Sun/NeXT AU format (big endian). *)
	|	MAJOR_RAW		(** RAW PCM data. *)
	|	MAJOR_PAF		(** Ensoniq PARIS file format. *)
	|	MAJOR_SVX		(** Amiga IFF / SVX8 / SV16 format. *)
	|	MAJOR_NIST		(** Sphere NIST format. *)
	|	MAJOR_VOC		(** VOC files. *)
	|	MAJOR_IRCAM		(** Berkeley/IRCAM/CARL *)
	|	MAJOR_W64		(** Sonic Foundry's 64 bit RIFF/WAV *)
	|	MAJOR_MAT4		(** Matlab (tm) V4.2 / GNU Octave 2.0 *)
	|	MAJOR_MAT5		(** Matlab (tm) V5.0 / GNU Octave 2.1 *)
	|	MAJOR_PVF		(** Portable Voice Format *)
	|	MAJOR_XI			(** Fasttracker 2 Extended Instrument *)
	|	MAJOR_HTK		(** HMM Tool Kit format *)
	|	MAJOR_SDS		(** Midi Sample Dump Standard *)
	|	MAJOR_AVR		(** Audio Visual Research *)
	|	MAJOR_WAVEX		(** MS WAVE with WAVEFORMATEX *)
	|	MAJOR_SD2		(** Sound Designer 2 *)
	|	MAJOR_FLAC		(** FLAC lossless file format *)
	|	MAJOR_CAF		(** Core Audio File format *)

type minor_format_t =
	|	MINOR_NONE
	|	MINOR_PCM_S8			(** Signed 8 bit data *)
	|	MINOR_PCM_16			(** Signed 16 bit data *)
	|	MINOR_PCM_24			(** Signed 24 bit data *)
	|	MINOR_PCM_32			(** Signed 32 bit data *)
	|	MINOR_PCM_U8			(** Unsigned 8 bit data (WAV and RAW only) *)
	|	MINOR_FLOAT			(** 32 bit float data *)
	|	MINOR_DOUBLE			(** 64 bit float data *)
	|	MINOR_ULAW			(** U-Law encoded. *)
	|	MINOR_ALAW			(** A-Law encoded. *)
	|	MINOR_IMA_ADPCM		(** IMA ADPCM. *)
	|	MINOR_MS_ADPCM		(** Microsoft ADPCM. *)
	|	MINOR_GSM610			(** GSM 6.10 encoding. *)
	|	MINOR_VOX_ADPCM		(** OKI / Dialogix ADPCM *)
	|	MINOR_G721_32		(** 32kbs G721 ADPCM encoding. *)
	|	MINOR_G723_24		(** 24kbs G723 ADPCM encoding. *)
	|	MINOR_G723_40		(** 40kbs G723 ADPCM encoding. *)
	|	MINOR_DWVW_12		(** 12 bit Delta Width Variable Word encoding. *)
	|	MINOR_DWVW_16		(** 16 bit Delta Width Variable Word encoding. *)
	|	MINOR_DWVW_24		(** 24 bit Delta Width Variable Word encoding. *)
	|	MINOR_DWVW_N			(** N bit Delta Width Variable Word encoding. *)
	|	MINOR_DPCM_8			(** 8 bit differential PCM (XI only) *)
	|	MINOR_DPCM_16		(** 16 bit differential PCM (XI only) *)


type endianness_t =
	|	ENDIAN_FILE			(** Default endianness for file format. *)
	|	ENDIAN_LITTLE		(** Force little endian format. *)
	|	ENDIAN_BIG			(** Force Big endian format. *)
	|	ENDIAN_CPU			(** Use same endianness as host CPU. *)


type file_format_t
(**
	An opaque type representing a sound file file format.

	It is constructed using either format or format_e.
*)

type error =
	|	No_error
	|	Unrecognised_format
	|	System
	|	Malformed_file
	|	Unsupported_encoding
	|	Internal
  
exception Error of (error * string)

type t
(**
	[Sndfile.t] An opaque type representing a open sound file.
*)

val format : major_format_t -> minor_format_t -> file_format_t
(**
	[Sndfile.format ma mi] constructs a file_format_t for use with
	sf_open for the supplied major format [ma], minor format [mi].
*)

val format_e : major_format_t -> minor_format_t -> endianness_t -> file_format_t
(**
	[Sndfile.format ma mi] constructs a file_format_t for use with
	sf_open for the supplied major format [ma], minor format [mi] and
	endianness [e].
*)

val openfile :
	?info : (open_mode_t * file_format_t * int * int) ->
	string ->
	t
(**
	[Sndfile.openfile fn] opens the file specified by the filename [fn] for
	read.

	[Sndfile.openfile (SFM_WRITE, fmt, ch, sr) fn] opens the file specified
	by the filename [fn] for write with the specified file_format_t, channel
	count and samplerate.

	[Sndfile.openfile (SFM_RDWR, fmt, ch, sr) fn] opens the file specified 
	by the filename [fn] for read/write with the sepcified file_format_t,
	channel count and samplerate.
*)

val close : t -> unit
(**
	[Sndfile.close f] closes the file [f].

	Attempting to read from or write to a file after it has been closed will
	fail.
*)

val read : t -> float array -> int
(**
	[Sndfile.read f a] read data from the file [f] into the supplied array
	[a] and return the number of float values read.

	For multi-channel files, the array length must be an integer multiple of
	the number of channels.
*)

val write : t -> float array -> int -> int
(**
	[Sndfile.write f a count] write count data from the supplied array [a] to the file
	[f] and return the number of float values written.

	For multi-channel files, the array length must be an integer multiple of
	the number of channels.
*)

val frames : t -> Int64.t
(**
	[Sndfile.frames f] returns the number of frames in the file [f].
*)

val samplerate : t -> int
(**
	[Sndfile.samplerate f] returns the sample rate of the file [f].
*)

val channels : t -> int
(**
	[Sndfile.channels f] returns the channel count for the file [f].
*)

val seek : t -> Int64.t -> seek_mode_t -> Int64.t
(**
	[Sndfile.seek f pos m] seeks to posiont [pos] of file [f] using
	the specified seek mode [m]. Returns offset from start of file.
*)

val compare : t -> t -> int
(**
	The comparison function for Sndfile.t, with the same specification as
    [Pervasives.compare].
*)

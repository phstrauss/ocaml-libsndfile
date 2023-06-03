(* Rudimentary testing of the Ocaml libsndfile wrapper. *)

let write_test filename =
	let fmt = Sndfile.format Sndfile.MAJOR_WAV Sndfile.MINOR_PCM_16 in
	let file = Sndfile.openfile ~info:(Sndfile.WRITE, fmt, 2, 44100) filename in
	let writecount = Sndfile.write file [| 0.0 ;  0.0 ;  0.0 ;  0.0 ;  0.0 ;  0.0 ;  0.0 ;  0.5 |] in
	Printf.printf "Wrote %d items.\n" writecount ;
	Sndfile.close file

let read_test filename =
	let file = Sndfile.openfile filename in
	Printf.printf "File contains %Ld frames.\n" (Sndfile.frames file) ;
	let data = Array.create 100 0.0 in
	let readcount = Sndfile.read file data in
	Printf.printf "Read %d items.\n" readcount ;
	Sndfile.close file

let finalize_test filename =
	let sub_open_file = 
		let file = Sndfile.openfile filename in
		ignore file
	in
	(* Compact the heap. *)
	Gc.compact () ;
	let pre_stat = Gc.stat () in
	sub_open_file ;
	(* Compact the heap again. *)
	Gc.compact () ;
	(* Compare before and after. *)
	let post_stat = Gc.stat () in
	if pre_stat.Gc.heap_words != post_stat.Gc.heap_words then
	(	Printf.printf "\nFinalize not working : before %d -> after %d\n\n" pre_stat.Gc.heap_words post_stat.Gc.heap_words ;
		exit 1
		)
	else ()

let bad_read_test filename =
	try
		let file = Sndfile.openfile filename in
		ignore file ;
		print_endline "Ooops, this should have failed." ;
		exit 1
	with
		Sndfile.Error (e, s) ->
			if s = "System error." then () else
			(	Printf.printf "Bad error '%s'\n" s ;
				exit 1
				)


let _ =
	print_endline "------------------------" ;
	let filename = "a.wav" in
	write_test filename ;
	read_test filename ;
	finalize_test filename ;
	bad_read_test "this_file_does_not_exist.wav" ;
	print_endline "Done : All passed."


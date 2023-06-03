module C = Configurator.V1

let sndfile_test = {|
#include <sndfile.h>

int main()
{
  printf("libsndfile header include test\n");
  return 0;
}
|}

let () =
  C.main ~name:"sndfile" (fun c ->
      let conf =
        let default = { C.Pkg_config.cflags = []; libs = ["-lsndfile"] } in
        match C.Pkg_config.get c with
        | None -> default
        | Some p -> begin
            match C.Pkg_config.query ~package:"sndfile" p with
            | None -> default 
            | Some conf -> conf
          end 
      in
      if not
        @@ C.c_test
          c
          sndfile_test
          ~c_flags:conf.cflags
          ~link_flags:conf.libs
      then
        failwith "No valid installation of libsndfile found."
      else
        C.Flags.write_sexp "c_flags.sexp" conf.cflags;
        C.Flags.write_sexp "c_library_flags.sexp" conf.libs)

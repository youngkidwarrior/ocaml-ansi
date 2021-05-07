(lang dune 2.0)

(name ansi)

(documentation "https://tmattio.github.io/ansi/")

(source
 (github tmattio/ansi))

(license MIT)

(authors "Christophe Troestler" "Vincent Hugot")

(maintainers "Christophe Troestler <Christophe.Troestler@umons.ac.be>")

(generate_opam_files true)

(package
 (name ansi)
 (synopsis "Basic control of ANSI compliant terminals and the windows shell")
 (description
  "Ansi is a module allowing to use the colors and cursor movements on ANSI terminals. It also works on the windows shell (but this part is currently work in progress).")
 (depends
  (ocaml
   (>= 4.08.0))
  dune
  (alcotest :with-test)
  (odoc :with-doc)))

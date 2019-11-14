(lang dune 1.11)
(name oci-web)
(using fmt 1.2)
(explicit_js_mode)

(generate_opam_files true)
(source (github craigfe/oci-web))
(license ISC)
(authors "Craig Ferguson")
(maintainers "Craig Ferguson")

(package
 (name oci-web)
 (synopsis "CI for web projects using OCurrent")
 (depends current current_docker current_git current_web logs fmt))


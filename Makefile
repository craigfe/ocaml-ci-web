


run:
	dune exec src/main.exe -- app \
		--github-app-id 47151 \
		--github-private-key-file /run/secrets/ocaml-ci-web.2019-11-19.private-key.pem \
		--github-account-whitelist ocurrent

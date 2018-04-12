# ur/web chatroom with github authentication

Build and run:

```bash
cat > github_app_config.ur << EOF
(* visit https://github.com/settings/developers to get these values. *)
(* set Authorization callback URL to http://localhost:8080/GH/authorized *)
val client_id = "xxx"
val client_secret = "yyy"
EOF

nix-shell
make deps run
```

myzshbot
========

Adding events
-------------
Simply modify http_router.zsh to include a test for the new event. Pull needed bits out of `jason`.

Testing
-------
1. Modify `http_router.zsh` as needed.
1. Start `nc -vvlp 7000` to catch the rpc message in one terminal.
1. Run `http.zsh` in another terminal.
1. Copy the webhook from the github interface to `test.body`
1. Run `test.curl` to submit the webhook in `test.body` to `http.zsh`

Deployment
----------
The recommended method is to a Docker image with the included `Dockerfile`.

Manual steps are basically running `irc.zsh` and `http.zsh` at the same time. Expose `8080/tcp` via a load balancer.

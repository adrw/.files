# KVM

KVM (keyboard-video-mouse) sharing is useful when using two computers at a single desk.

For a virtual KVM, [Barrier](https://github.com/debauchee/barrier/) is a good virtual option.

To enable SSL between server/client machines, run the following (for macOS, for others, see [this Github issue](https://github.com/debauchee/barrier/issues/231#issuecomment-962421337)).

```
$ cd /Users/<user>/Library/Application Support/barrier/SSL
$ openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:4096 -keyout Barrier.pem -out Barrier.pem
$ # restart barrier application
```


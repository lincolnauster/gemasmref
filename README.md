gemasmref
=========

An x86 assembly reference for Geminispace.

> Note: this is not complete. This has just been collecting dust in my
> home partition for a bit, and I figured I'd publish the source just
> in case this base is interesting to anyone. I may get around to
> working on this a bit later. If you want to take it up, feel free,
> but note the licenses!


overview
--------

gemasmref is a single-binary server providing access to an x86
assembly reference. Its public interface is fairly complete,
supporting searches in both Intel and GNU/AT&T syntax.

Just for fun, it's written in (SWI) Prolog.

Do note that this is a proof-of-concept, I've not yet gotten around to
writing in every instruction (feel free to help out!).


building
--------

If you're on NixOS or otherwise have the Nix package manager
installed, you should probably `nix build` yourself a
binary. Otherwise, compile with SWI Prolog. The entry point is the
`gemini` goal.


deploying
---------

gemasmref relies on two environment variables, `GEMASM_TLS_CERT` and
`GEMASM_TLS_KEY`, which should point to a TLS certificate file and a
TLS private key, respectively. Encryption passwords are not (yet)
supported.


developing
----------

Gemini requires a TLS certificate for all environments, so you should
have the environment variables `GEMASM_TLS_CERT` and `GEMASM_TLS_KEY`
set to point to some valid files. If that's too much effort, and
you've got Nix installed, run `nix develop` to get a shell where
everything (certs, compilers, etc) just works.


licensing
---------

Most source is released under the GNU Affero General Public
License. Note, however, that *not all source code contained within
this repository is licensed as such.* Some of it (that inside the
`ref` directory) is adapted from [AMD's AMD64 Architecture
Programmer's Manul, Volume 3][ref]. No copyright over this is claimed,
and no attempt to license it is made. (I may not actually have the
rights to redistribute it in the first place, so do with that what you
will :).

[ref]: https://www.amd.com/system/files/TechDocs/24594.pdf

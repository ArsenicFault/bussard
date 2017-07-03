# Bussard

<img src="https://p.hagelb.org/bussard.png" alt="screenshot" />

A spaceflight programming adventure.

Read the [in-game manual](manual.md) for a taste of how the game works.

Read
[an interview on the motivation and background for the game](http://hifibyapg.com/volume-3.html#A.conversation.with.Phil.Hagelberg.on.Bussard)
(some spoilers, some outdated info).

## Playing

When you're in flight mode, the arrow keys control the ship's engines
and turning thrusters. Keys to access the ship's computer's various
functions are listed on the side of the screen.

The ship's computer can be accessed using `ctrl-enter`, and from
the console you can read the quick start guide by running `man("quickstart")`.
The full reference manual is available with `man("manual")`, but you
won't need that right away.

Recommended soundtrack:
[Contingency](http://music.biggiantcircles.com/album/contingency) by
[Big Giant Circles](http://www.biggiantcircles.com/) though Ben Prunty's
[FTL soundtrack](https://benprunty.bandcamp.com/album/ftl) is a great
fit too.

## Installation

Releases for each platform are [on itch.io](https://technomancy.itch.io/bussard).
Windows and Mac OS X releases are standalone, but `.love` file releases require having
[LÖVE](https://love2d.org). Version 0.9.x is supported, but 0.10.x or higher is
recommended for syntax highlighting support.

When running from source, type `love .` from a checkout.

<img src="https://p.hagelb.org/bussard-repl.png" alt="repl screenshot" />

One problem when running from source is that when new features are
added, key bindings for them are added to the default config, but
existing saved games will continue on using the same config. You can
replace your ship's config with the current default config `ctrl-f1`;
your existing config source will be backed up.

## Status

Currently most of the engine features are coded, some more polished than
others. However, there are only a handful of missions, and the characters are
not sketched out in much detail yet.

See the list of [open issues](https://gitlab.com/technomancy/bussard/issues) to
see upcoming features. The [changelog](Changelog.md) lists when recent
user-visible changes were added in which releases.

The [contributing guide](Contributing.md) contains details about the structure
of the codebase and how to submit good patches.

The game contains programming challenges you must solve in order to
progress. Eventually the goal is that you will be able to learn it without any
(or much) prior programming experience through in-game hints and tutorials.

<img src="https://p.hagelb.org/bussard-edit.png" alt="edit screenshot" />

## FAQ

**Q:** How do I change the controls?  
**A:** Press `ctrl-o` then type "src.config" to open the main config file. The keys here are mostly for flight mode. At the bottom you can see where it loads other modes in files like "src.edit" or "src.mail". Open these other files with `ctrl-o` if you want to change keys for those modes. Find the key binding you want to change, and change the second argument to `define_key` to the keycode you want to use. For a complete list of keycodes, run `man("keycodes")`. Once you've made the changes, hit `esc` to go back to flight mode, and then press `ctrl-r` to load them. Note that after using the editor you may need to press `ctrl-pagedown` or `ctrl-pageup` a few times to get back to console, as console is just a buffer called `*console*` in the editor.

**Q:** How do you match orbit with a station or planet?  
**A:** Remember that newtonian motion means your controls affect your velocity rather than directly controlling your motion. Don't accelerate towards the station; instead accelerate so your trajectories cross at the same point.

**Q:** I'm stuck on a mission!  
**A:** If you've received a message, check the bottom of the screen when it's open to see if it's one that you can reply to by pressing `alt-enter`. This is how you initially accept missions, but some missions will need you to respond to messages you get in order to proceed.

## Influences

* [Escape Velocity](https://www.ambrosiasw.com/games/ev/) (gameplay)
* [Kerbal Space Program](https://kerbalspaceprogram.com/en/) (mechanics)
* [Marathon Trilogy](http://marathon.bungie.org/story/) (story)
* [A Fire upon the Deep](http://www.tor.com/2009/06/11/the-net-of-a-million-lies-vernor-vinges-a-fire-upon-the-deep/) (story)
* [Anathem](http://www.nealstephenson.com/anathem.html) (story, philosophy)
* [Mindstorms](https://www.goodreads.com/book/show/703532.Mindstorms) (philosophy)
* [GNU Emacs](https://www.gnu.org/software/emacs/) (architecture)
* [Unix](https://en.wikipedia.org/wiki/Unix) (architecture)
* [Atomic Rockets](http://www.projectrho.com/public_html/rocket/) (science)
* [Planescape: Torment](https://www.gog.com/game/planescape_torment) (story, gameplay)
* [Meditations on Moloch](https://slatestarcodex.com/2014/07/30/meditations-on-moloch/) (philosophy)
* [SpaceChem](https://www.gog.com/game/spacechem) (puzzle design)

## Licenses

Original code, prose, and images copyright © 2015-2017 Phil Hagelberg and contributors

Distributed under the GNU General Public License version 3 or later; see file COPYING.

See [credits](credits.md) for licensing of other materials.

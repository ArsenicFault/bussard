# Bussard

<img src="http://p.hagelb.org/bussard.png" alt="screenshot" />

A space flight programming adventure game. Mine, trade, upgrade, and
unlock the potential of your spacecraft by hacking on the code that
makes it tick.

Read the [in-game manual](manual.md) for a taste of how the game works.

Read [an interview on the motivation and background for the game](http://hifibyapg.com/volume-3.html#A.conversation.with.Phil.Hagelberg.on.Bussard) (some spoilers).

## Playing

When you start the game, you'll notice you have a couple emails. Hit
`ctrl-m` to open up the mail client and read the messages in your
inbox. When you're done, hit escape to go back to flight mode.

Your next priority is to rendezvous with the nearby station. Press
`tab` until your targeting indicator in your HUD shows the
station. The targeting line will always point in the direction of your
target; the blue striped line indicates your current trajectory. Head
towards the station and try to make your trajectory match its orbit,
but keep an eye on your velocity and fuel supply. If you accelerate
too much, you may not have enough fuel to match velocity with the
station. Once you get close, it will be easier to match velocity if
you zoom in with `=`.

Once you are in orbit around the station, and are in range, the line
pointing towards the station will turn light green. Press backtick and
type `ssh()` to establish a connection. You can see all the commands
available on the station by typing `ls /bin`, but at this time you
only need to concern yourself with the `upgrade` command. Run `upgrade
buy laser`, then `logout` followed by `man("laser")` to learn how to
use the laser. You will need to edit your config file (with
`ctrl-enter`) to add a key binding to turn on the laser, as explained
on the laser's manual page.

From there it's off to find an asteroid to mine, and then the galaxy
is yours to explore. To jump to another system, find a portal and
press `ctrl-s` when you are within range. You'll want to check out
the ship's main manual with `man()` at some point though.

Recommended soundtrack:
[Contingency](http://music.biggiantcircles.com/album/contingency) by
[Big Giant Circles](http://www.biggiantcircles.com/) though Ben Prunty's
[FTL soundtrack](https://benprunty.bandcamp.com/album/ftl) is a great
fit too.

## Installation

Releases for each platform are [on itch.io](https://technomancy.itch.io/bussard).
Windows and Mac OS X releases are standalone, but Linux releases require having
[LÖVE](http://love2d.org) 0.9.x or 0.10.x installed.

When running from source, type `love .` from a checkout.

<img src="http://p.hagelb.org/bussard-repl.png" alt="repl screenshot" />

One problem when running from source is that when new features are
added, key bindings for them are added to the default config, but
existing saved games will continue on using the same config. You can
replace your ship's config with the current default config using
`ship.src.config = default_config`.

## Status

Currently most of the engine features are coded, some more polished
than others. However, there are only a handful of missions, and the
characters are not sketched out in much detail at all yet.

See the list of
[open issues](https://gitlab.com/technomancy/bussard/issues) to see
upcoming features. The [changelog](Changelog.md) lists when recent
user-visible changes were added in which releases.

<img src="http://p.hagelb.org/bussard-edit.png" alt="edit screenshot" />

During development it may be expedient to run `ship.cheat.comm_range = 9999999`
in order to make testing login interaction easier.

## FAQ

**Q:** How do I change the controls?  
**A:** Press `alt-o` then type "src.config" to open the main config file. The keys here are mostly for flight mode. At the bottom you can see where it loads other modes in files like "src.edit" or "src.mail". Open these files if you want to change keys for those modes. Find the key binding you want to change, and change the second argument to `define_key` to the keycode you want to use. For a complete list of keycodes, run `man("keycodes")`. Once you've made the changes, hit `esc` to go back to flight mode, and then press `ctrl-r` to load them.

**Q:** What can I do to improve the frame rate?  
**A:** The biggest performance drag is calculating trajectories. Reduce the calculations with `ship.trajectory = 32` and you should notice a dramatic speed boost. If you drop the trajectory length, you may want to boost the `ship.trajectory_step_size` to compensate.

**Q:** How do you match orbit with the station?  
**A:** Remember that newtonian motion means your controls affect your velocity rather than directly controlling your motion. Don't accelerate towards the station; instead accelerate so your trajectories line up. The stripes on your ship's trajectory and the station's trajectory represent equal amounts of time, if your trajectories cross at the same stripe it means you will be in the same place at the same time.

**Q:** Why does my trajectory sometimes wobble a lot?  
**A:** High velocity movement near the base of a gravity well can be non-deterministic, which throws off the estimated trajectory.

**Q:** Where are the missions?  
**A:** There are currently only a few missions. The main chain starts at Tana Prime. Open up the "jobs" folder in your mail client to see available missions.

## Influences

* [Escape Velocity](http://www.ambrosiasw.com/games/ev/) (gameplay)
* [Kerbal Space Program](https://kerbalspaceprogram.com/en/) (mechanics)
* [Marathon Trilogy](http://marathon.bungie.org/story/) (story)
* [A Fire upon the Deep](http://www.tor.com/2009/06/11/the-net-of-a-million-lies-vernor-vinges-a-fire-upon-the-deep/) (story)
* [Anathem](http://www.nealstephenson.com/anathem.html) (story, philosophy)
* [Mindstorms](https://www.goodreads.com/book/show/703532.Mindstorms) (philosophy)
* [GNU Emacs](https://www.gnu.org/software/emacs/) (architecture)
* [Unix](https://en.wikipedia.org/wiki/Unix) (architecture)
* [Atomic Rockets](http://www.projectrho.com/public_html/rocket/) (science)
* [Planescape: Torment](https://www.gog.com/game/planescape_torment) (story, gameplay)
* [Meditations on Moloch](http://slatestarcodex.com/2014/07/30/meditations-on-moloch/) (philosophy)

## Licenses

Original code, prose, and images copyright © 2015-2016 Phil Hagelberg and contributors

Distributed under the GNU General Public License version 3 or later; see file COPYING.

See [credits](credits.md) for licensing of other materials.

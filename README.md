## Mosh Paper Scissors

MPS is a massively multiplayer rock paper scissors action game.

## Requirements

[LÖVE](https://love2d.org) (tested with v11.3)

## Building and running

```shell
$ make
$ open mps.love
```

`make` will create a zip file called `mps.love`, meant to be played using LÖVE.

## Controls

Player one uses the keyboard

- arrow left and right: move left or right
- arrow up: jump
- A: rock
- S: paper
- X: scissors

Other players can join in by just plugging in a USB controller. I put no player
limit on the game, so I don't know if there is one.

- dpad: move left or right
- button 1: jump
- button 2: attack

If you are attacked, you can counter using the correct attack according to
classig rock, paper scissors rules. If you counter attack correctly in time,
you kill the other player, otherwise the attacker kills you.

Last player standing wins.

## Cool stuff that enabled me to make this game

This is from memory, it was seven years ago:

- deflemask: I maybe made one track in this
- sunvox: I made the music in this I think
- jpixel: for drawing the sprites

Libraries (you can see them in the `src` directory):

- anim8.lua
- bit.lua
- lume.lua
- lurker.lua
- sfxr.lua

## Copyright

This game is licensed under the MIT license, (see LICENSE for details).

song_0.mp3 is a cover I made of the "Janken" theme from Alex Kidd in Miracle World.  
song_1.mp3 is an adapted version of the same song.

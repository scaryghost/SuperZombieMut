SuperZombieMut
==================
Gives Killing Floor specimens new abilities

## Author
Scary Ghost

## Install
Copy the contents in the system folder to your Killing Floor system folder and the contents in textures to your KF 
textures folder.

## Usage
Add the "Super Zombie" mutator to the list of active mutators.  The game will spawn the modified specimens in place of 
their default counterparts.  A configuration menu is available which allows users to select what specimens they wish to 
replace.  For dedicated servers, you should double check the wedadmin configuration page to make sure your desired 
specimens are active if it you are running the mutator for the first time.

### Bare Mode
To provide compatibility with other zed replacement mutators and sandbox games, the mutator can be put in bare mode.  While in this mode, all the mutator does is:

1. Add itself to the package list
2. Setup custom interaction and replication info classes
3. Manage fp evolution

Bare mode can be toggled be checking the box titled "Enable bare mutator mode" or adding

    bareMutatorMode=true

to the SuperZombieMut.ini config file

### Monster List
The package name for the specimens is "SuperZombieMut" and the available specimens are:

    ZombieSuperFP
    ZombieSuperBoss
    ZombieSuperGorefast
    ZombieSuperStalker
    ZombieSuperSiren
    ZombieSuperScrake
    ZombieSuperHusk
    ZombieSuperBloat
    ZombieSuperCrawler
    ZombieSuperClot

## Special Thanks
    Benjamin            Writing up a "how to" for creating mutators
    Brute coders        Brute mutator source code helped me figure out how to insert my modded specimens 
                        into the game
    Testers             Nikari, Fractal, [DoP] Cap, Tech Burn, Gore Torn, Nurse. Jamie Jameson, 
                        Reaping - The Runk, Xandirs, DM*, BulletMorgue, Sakumaru, Fang.HD, AnTrix, 
                        Riceman

## Source Code
The source code is available on the project's GitHub page  
https://github.com/scaryghost/SuperZombieMut

## Change Log
To view a detailed change log, please view the releaes notes for the specific version:  
https://github.com/scaryghost/SuperZombieMut/releases/tag/2.3.2

A complete list of specimen changes maybe viewed on the mutator's wiki:  
https://github.com/scaryghost/SuperZombieMut/wiki

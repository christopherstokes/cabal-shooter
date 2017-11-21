#!/bin/fish

set ticExec 'tic80'
set ticFile 'cabal-shooter.tic'
cp ~/.local/share/com.nesbox.tic/TIC-80/$ticFile ./
eval $ticExec $ticFile -code game.moon

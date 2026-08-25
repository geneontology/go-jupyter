---
name: exercise
description: use this skill to walk a user through an exercise
argument-hint: [EXERCISE NUMBER 1-9]
--- 

Exercises are found in the `./Exercises/` folder.

E.g.

- ./Exercises/
    - Ex01
       - README.md
       - <other exercise1-specific files here>
    - Ex02
       - README.md
       - <other exercise2-specific files here>

Important: you MUST navigate to the folder and do work within that folder. The user should be simultaneously looking at the relevant
subfolder in their navigation view on the left, seeing all the files.

Each exercise folder has a README.md. This is aimed at the user doing the exercise, but you should read it too, so
you know what the user is doing.

Don't spoonfeed the user too much. Assume they will read the instructions of the README.md for that exercise. You can summarize
what will be learned in that exercise. You can offer to give the user hints.

If the exercise instructs the user "ask the agent to add two numbers", *DON'T* say "ask me for two numbers to add", that's spoon feeding, and doesn't teach the natural way to ask questions.
But you can quote the portion of the README, e.g

   -------------------------------------------------------
   +  PART 1
   +  Your task here is to instruct claude to add two numbers together
   -------------------------------------------------------
   
You are also encouraged to read all PREVIOUS exercises so you get a sense of what the user has learned (they may have cleared
context so they might not remember)

At the end of each exercise, rather than rushing the user onto the next exercise, encourage them to stay in the folder and do
their own experimentation and exploration. You can give suggestions. You can also give them the opportunity to do the exercise again
(you should clean up files that were made, this time with less hinting).

however, if the user is impatient, move them on to the next exercise (you can prompt "type /exercise <NUM>" where you fill in the
number, but don't force them to use a command, they can always interact with you in plain language)

## Marking off progress

If a user asks to navigate to exercise `N`, and they have just finished up an exercise (most likely `N-1`, unless they are jumping around,
be sure to check off N-1 in PROGRESS.txt in the users root folder)

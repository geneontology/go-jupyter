# Exercise 01

The goal of this exercise is just to get familiar with the terminal-based chat interface, using it in the same way
as web chat like ChatGPT, but then gradually incorporating simple tool use.

Note that we intentionally avoid biological examples in this exercise as we want to keep things simple
without any distractions.

At any time you can just type in your chat window "help me" or "I don't know what I'm meant to be doing". Let claude guide you!

## Getting started

You have a normal chat interface, you can try asking any questions you like (but we ask you avoid biology or GO topics for now -- we'll get to that!)

As a starting point, I suggest you ask:

```
> What are some sights to see in Geneva?
```

You can substitute Geneva for any other major city (try not to get too clever just now, no entering an obscure English village of seven people,
stick to well-known places; we can get to obscure knowledge later)

If you like you can interact further and tell Claude what things you like and don't like; e.g. outdoor vs indoor

## Introduction to tool use: File Writing and appending

Next, instruct the Claude:

```
> Create a markdown file with the sights to see
```

It will create a file called `Geneva.md` (or whatever city you chose). You can always ask it to rename

You should be able to see the file in the sidebar. Clicking it will open a tab with the file contents.

How does it look?

* UNLOCK: tool use. Congratulations, you have used your first *Tool*

file writing is a general purpose built-in tool that comes with claude

## File editing appending

Ask to add more information to the file. You can ask for more sights. Or you could ask for a translation to French or Spanish to be appended. Up to you!

* UNLOCK: file editing

## Tool use: general purpose file tools

Now ask:

```
> How many words in the file?
```

(you can also how many characters, or lines in the file, or how many letters `s`)

* UNLOCK: unix tool use.

Congratulations! You are now a command line wizard! All those strange
commands you see developers typing in terminals in order to do cool
and powerful things? You can do all of these things without knowing
anything about unix or the command line!

* EXERCISE 1 Completed! The agent should tick this off in PROGRESS.txt in the home directory now.

## Open Ended Exploration

Before moving on to the next exercise, feel free to explore more, you can try things like:

- Adding a second document about a different city
- Asking for further edits on the existing documents
- Combining documents into one
- ...




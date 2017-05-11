# Contributing to OAA Development

First off, thanks for thinking about contributing to the development of OAA, we believe this exciting protocol has a lot of potential and together we can make it even better off than it is.  This document should serve as a guideline for all who seek to contribute.  It is mostly a style guide and a plea to use your best judgement when putting together PRs.

## Branching

You should always work from a feature branch, and if a reasoanble amount of work has gone on, be sure to rebase your fork/branch from the master repository to ensure your PR will merge smoothly.  The only person who can and regularly will commit directly to master will be me, @mgregoro, presumably because I am rapidly building out the software or documentation directly.

## Tests

If you make changes to the code you should include at least a few tests testing the positive / negative outcomes of your new functionality.  Try and show that you've thought about at least 1-2 scenarios that might trip up your code and have taken care of them.  No need to go crazy with edge cases.

### The Test Suite Should Pass

Only bother submitting your PR if the entire test suite (`prove -lv` is your friend) passes against your local rebased branch.  If a test you didn't write fails because of your new changes try and figure out what's causing it to fail.  Keep in mind that the problem may not be with your code but with the code the test was originally written for.  Don't be afraid to hurt feelings, fix their code if it's what's at fault, and include it in your PR.  Just make sure all tests pass

## Style

Different languages have different style requirements, here are the style requirements for OSiRIS' AA subproject

### Perl, Shell, Java & C

Mostly outlined in the [.perltidyrc.conf](.perltidyrc.conf) file.  In short...

 * 120 column character limit
 * curlys on the same line
 * 4 SPACE indent, if you commit tabs I may get violent
 * cuddle your elses
 * don't change indentation on long lines wrapped
 * ignore the length of `#`, `//` *side comments*, they can go over 120 cols
 * break after all the standard operators plus ". << >> -> && || //"

Feel free to run perltidy on your work before committing it, use the .perltidyrc.conf file at the base of the project and your output should be golden.
 
### Javascript, (non auto-generated) JSON, (non auto-generated) CSS, LESS, SASS, XML, and HTML

 * 2 SPACE indent... 
 * cuddle your elses
 * curlys on the same line
 * no column character limit due to canonicalization of XML, long base64 strings and other stuff, but be reasonable

If your PR does not respect the style guide it is not a "big deal" but you will lose credit for code that's styled incorrectly because I reserve the right to refactor/rewrite/reformat your patch and apply it myself.  I will be sure to @ mention you in the commit in case this happens.

## Releases

We are currently working toward having a working alpha which will quickly become a working Beta.  Releases may begin in the Beta stage.  Check back here for more info as we get further along in the project
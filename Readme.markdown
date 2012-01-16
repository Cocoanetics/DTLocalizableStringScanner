DTLocalizableStringScanner
==========================

This project aims to duplicate and enhance the functionality found in the `genstrings` utility provided by Apple. The Demo builds a command line utility `genstrings2` which works like the original but using more modern techniques. The Core contains classes and categories to add this scanning functionality to Linguan.

Follow [@cocoanetics](http://twitter.com/cocoanetics) on Twitter.

License
------- 
 
It is open source and covered by a standard BSD license. That means you have to mention *Cocoanetics* as the original author of this code. You can purchase a Non-Attribution-License from us.

Known Issues
------------

Documentation on the inner workings of `genstrings` is non-existent, so there is lots of guessing involved.

- so far no deduplication is done, genstrings only writes a token with exactly same comment and key once. 
- if a token differs but has same key genstrings emits a warning, we ignore that
- genstrings seems to internally unescape character sequences, we just copy them as they are. This causes the sort order to differ with non-alpha characters.

If you find an issue then you are welcome to fix it and contribute your fix via a GitHub pull request.
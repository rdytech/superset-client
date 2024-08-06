# Publishing

The team at ReadyTech currently manages the gem and new version releases.

As per demand / usage of the public gem, the team at ReadyTech will soon move to primarily hosting
the gem on RubyGems.

Until then, ReadyTech will continue to host a private Gemfury version as well as RubyGems.


## ReadyTech private Gemfury repo

### Releasing a new version

On develop branch make sure to update `Superset::VERSION` and `CHANGELOG.md` with the new version number and changes.  

Build the new version and upload to gemfury.

`gem build superset.gemspec`

### Publish to Gemfury

ReadyTech hosts its own private gemfury remote repo.

Get the latest develop into master

    git checkout master
    git pull
    git fetch
    git merge origin/develop

Tag the version and push to github

    git tag -a -m "Version 0.1.0" v0.1.0
    git push origin master --tags

Push to gemfury or upload the build manually in the gemfury site.

    git push fury master

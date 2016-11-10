Unify reports from all your tests runs and send them as one.

Run your own hosted batching [![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Automated setup

Use [codeclimate batch](https://github.com/grosser/codeclimate_batch)

## Manual usage

```Ruby
# only do when running on master branch ... see codeclimate_batch for details
ENV["TO_FILE"] = "1"
ENV["CODECLIMATE_REPO_TOKEN"] = "XXXX"

`rm -rf #{Dir.tmpdir}/codeclimate-test-coverage-*` # cleanup old reports
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

... run tests ...

file = Dir.glob("#{Dir.tmpdir}/codeclimate-test-coverage-*").first

... send report
```

### Send report

```
curl -X POST --data-binary @report.json https://cc-amend.herokuapp.com/amend/some_random_key?count=4
# => waiting for 3 more reports on some_random_key
# => waiting for 2 more reports on some_random_key
# => waiting for 1 more reports on some_random_key
# => sent 4 reports
```

You can send reports from [Travis](https://travis-ci.org/) manually. This relies on the repository you're reporting from using `gem 'codeclimate-test-reporter', '~> 1.0.2'` &mdash; add this to your `.travis.yml` file:

```
after_script:
  # Change the `count` parameter to match the number of test suites you're sending

  - curl -X POST --data-binary @coverage/.resultset.json https://<<YOUR APP>>.herokuapp.com/amend/<<REPOSITORY NAME>>-$TRAVIS_BUILD_NUMBER?count=4
```

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/amend.png)](https://travis-ci.org/grosser/amend)

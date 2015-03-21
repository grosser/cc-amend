Unify reports from all your tests runs and send them as one.

```
curl -X POST --data-binary @report.json https://cc-amend.herokuapp.com/amend/some_random_key?count=4
# => waiting for 3 more reports on some_random_key
# => waiting for 2 more reports on some_random_key
# => waiting for 1 more reports on some_random_key
# => sent 4 reports
```

If you have multiple reports first unify them using `file, content = CodeClimate::TestReporter::Client#unify_simplecov(files)`
`gem "codeclimate-test-reporter", git: "https://github.com/grosser/ruby-test-reporter.git", ref: "grosser/merge2"`

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/amend.png)](https://travis-ci.org/grosser/amend)

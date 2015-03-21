Unify reports from all your tests runs and send them as one.

### Generate reports

```Ruby
ENV["TO_FILE"] = "1"
ENV["CODECLIMATE_REPO_TOKEN"] = "XXXX"

`rm -rf #{Dir.tmpdir}/codeclimate-test-coverage-*` # cleanup old reports
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

... run tests ...

file = Dir.glob("#{Dir.tmpdir}/codeclimate-test-coverage-*").first

... see below
```

### Send report

```
curl -X POST --data-binary @report.json https://cc-amend.herokuapp.com/amend/some_random_key?count=4
# => waiting for 3 more reports on some_random_key
# => waiting for 2 more reports on some_random_key
# => waiting for 1 more reports on some_random_key
# => sent 4 reports
```

### Multiple reports
Unify them before sending:

```Ruby
# Gemfile
gem "codeclimate-test-reporter", git: "https://github.com/grosser/ruby-test-reporter.git", ref: "grosser/merge2"

# app
require 'json'
files = Dir.glob("#{Dir.tmpdir}/codeclimate-test-coverage-*")
content = CodeClimate::TestReporter::Client.new.send(:unify_simplecov, files)
File.write("report.json", JSON.dump(content))
```

and then send as shown above


Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/amend.png)](https://travis-ci.org/grosser/amend)

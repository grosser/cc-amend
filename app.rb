require 'sinatra'
require 'dalli'
require 'codeclimate-test-reporter'

%w[SERVERS USERNAME PASSWORD].each { |k| ENV["MEMCACHE_#{k}"] ||= ENV["MEMCACHIER_#{k}"] }
STORE = Dalli::Client.new(nil, compress: true)

def lock(key)
  lock = "#{key}.lock"
  sleep 0.01 until STORE.add(lock, '1', 10) # get the lock
  yield
ensure
  STORE.delete(lock)
end

def incr(key)
  key = "#{key}.count"
  index = STORE.get(key).to_i + 1
  STORE.set(key, index)
  index
end

def with_token(token)
  key = "CODECLIMATE_REPO_TOKEN"
  ENV[key] = token
  yield
ensure
  ENV.delete key
end

get "/" do
  headers('Content-Type' => "text/plain")
  "Welcome to cc-amend\nsource is at https://github.com/grosser/cc-amend\njust `curl -X POST --data-binary @report.json /amend/some_random_key?count=10&token=TOKEN` as much as you want\nand get it back with curl /amend/some_random_key\nand it will send 1 unified report to code-climate when done"
end

post "/amend/:key" do
  key = params.fetch("key")
  count = params.fetch("count").to_i
  data = request.body.read
  index = nil

  # store the data
  lock key do
    index = incr(key)
    raise "Too many parts" if index > count
    STORE.set("#{key}.#{index}", data)
  end

  missing = count - index

  message = if missing == 0
    Dir.mktmpdir do |dir|
      count.times do |i|
        partial_key = "#{key}.#{i+1}"
        data = STORE.get(partial_key) || raise("Looks like #{partial_key} is expired :(")
        File.write("#{dir}/report-#{i}.json", data)
      end

      client = CodeClimate::TestReporter::Client.new
      print "Sending #{count} reports to #{client.host} ..."

      files = Dir.glob("#{dir}/*")
      file, results = client.send(:unify_simplecov, files)
      results = JSON.load(results)

      with_token results.fetch("repo_token") do
        client.post_results(results)
      end
      "sent #{count} reports"
    end
  else
    "waiting for #{missing} more reports on #{key}"
  end

  puts message
  message
end

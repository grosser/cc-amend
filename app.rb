require 'sinatra'

require 'codeclimate-test-reporter'
require 'codeclimate_batch'

# heroku process dies after 30s, so might as wait as long as possible, also saw timeouts on big reports multiple times
CodeClimate::TestReporter.configuration.timeout = 30

# initialize cache
require 'dalli'
%w[SERVERS USERNAME PASSWORD].each { |k| ENV["MEMCACHE_#{k}"] ||= ENV["MEMCACHIER_#{k}"] }
STORE = Dalli::Client.new(nil, compress: true)

# otherwise blows up trying to parse the post body as form on heroku since big json blob looks like deeply nested form
# alternatively set `-H "Content-Type:application/json"`
Rack::Request.class_eval do
  def POST
    {}
  end
end

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
  key = params["key"] || halt(400, "Need key")
  count = (params["count"] || halt(400, "Need count parameter")).to_i

  data = request.body.read
  halt 400, "Invalid JSON submitted, must start with {" unless data.start_with?("{")
  index = nil

  # store the data
  lock key do
    index = incr(key)
    halt 400, "Too many parts for #{key}" if index > count
    STORE.set("#{key}.#{index}", data)
  end

  missing = count - index

  message = if missing == 0
    Dir.mktmpdir do |dir|
      count.times do |i|
        partial_key = "#{key}.#{i+1}"
        data = STORE.get(partial_key) || raise("Looks like #{partial_key} is expired :(")
        STORE.delete(partial_key)
        File.write("#{dir}/report-#{i}.json", data)
      end

      client = CodeClimate::TestReporter::Client.new
      print "Sending #{count} reports to #{client.host} ..."

      files = Dir.glob("#{dir}/*")
      token = File.read(files.first)[/"repo_token":"([^"]+)"/, 1] || halt(400, "repo_token not found in json")

      with_token token do
        result = CodeclimateBatch.unify(files)
        client.post_results(result)
      end
      "sent #{count} reports for #{key}"
    end
  else
    "waiting for #{missing}/#{count} reports on #{key}"
  end

  puts message
  message
end

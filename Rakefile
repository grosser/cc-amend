require "bundler/setup"
require "tempfile"

def server(extra=nil)
  command = File.readlines("Procfile").first.strip.
    sub('web: ', '').
    sub('$PORT', '3000').
    sub('$RACK_ENV', 'development')
  exec "#{command} #{extra}"
end

def child_pids(pid)
  pipe = IO.popen("ps -ef | grep #{pid}")

  pipe.readlines.map do |line|
    parts = line.split(/\s+/)
    parts[2].to_i if parts[3] == pid.to_s and parts[2] != pipe.pid.to_s
  end.compact
end

task :server do
  server
end

task :default do
  pid = fork { server ">/dev/null 2>&1" }
  begin
    sleep 5 # wait for server to start

    key = "a-key-#{rand(99999999)}"

    # test the welcome page
    result = `curl --silent '127.0.0.1:3000'`
    raise "Server version failed: #{result}" unless result.include?("Welcome to cc-amend")

    3.times do |i|
      result = `curl --silent -X POST '127.0.0.1:3000/amend/#{key}?count=4&token=TOKEN' --data "#{i}#{i}#{i}"`
      index = 3 - i
      raise "Server amend #{i} failed: #{result}" unless result.include?("waiting for #{index} more reports on #{key}")
    end
  ensure
    (child_pids(pid) + [pid]).each { |pid| Process.kill(:TERM, pid) }
  end
end

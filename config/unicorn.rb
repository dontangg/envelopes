# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete documentation.

# Set environment to development unless something else is specified
env = ENV["RAILS_ENV"] || "development"

worker_processes 2 # amount of unicorn workers to spin up

# This is good for Rails and for New Relic
preload_app true

timeout 30         # restarts workers that hang for 30 seconds

if env == "production"
  root = "/home/ec2-user/apps/envelopes/current"

  pid "/home/ec2-user/apps/envelopes/shared/pids/unicorn.pid"
  listen "/tmp/unicorn.envelopes.sock"

  # Help ensure your application will always spawn in the symlinked
  # "current" directory that Capistrano sets up.
  working_directory root

  stderr_path "#{root}/log/unicorn.log"
  stdout_path "#{root}/log/unicorn.log"
end

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end


  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # This enables 0 downtime deploys.
  old_pid_file = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid_file)
    old_pid = File.read(old_pid_file).to_i
    if server.pid != old_pid
      begin
        # kill the old unicorn master
        server.logger.info("sending QUIT to #{old_pid}")
        Process.kill("QUIT", old_pid)
      rescue Errno::ENOENT, Errno::ESRCH
        # someone else did our job for us
      end
    end
  end
end

after_fork do |server, worker|

  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection (since "preload_app true")
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)
end


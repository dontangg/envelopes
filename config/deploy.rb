require "bundler/capistrano"

set :application, "envelopes"
set :repository,  "git://github.com/dontangg/envelopes.git"

set :scm, :git

# set :deploy_to "/u/apps/#{application}"

role :web, "50.56.208.109"                          # Your HTTP server, Apache/etc
role :app, "50.56.208.109"                          # This may be the same as your `Web` server
role :db,  "50.56.208.109", :primary => true        # This is where Rails migrations will run
#role :db,  "your slave db-server here"

set :user, "app_user"

# It complained about no tty, so use pty... no profile scripts :(
# http://weblog.jamisbuck.org/2007/10/14/capistrano-2-1
default_run_options[:pty] = true

# Since we're using pty, load the path ourselves
set :default_environment, {
  "PATH" => "/home/app_user/.rbenv/shims:/home/app_user/.rbenv/bin:$PATH"
}


namespace :deploy do
  desc "Zero-downtime restart of Unicorn"
  task :restart, roles: :app, :except => { :no_release => true } do
    run "kill -s USR2 `cat /tmp/unicorn.envelopes.pid`"
  end

  desc "Start Unicorn"
  task :start, roles: :app, :except => { :no_release => true } do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D"
  end

  desc "Stop Unicorn"
  task :stop, roles: :app, :except => { :no_release => true } do
    run "kill -s QUIT `cat /tmp/unicorn.envelopes.pid`"
  end 
end

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

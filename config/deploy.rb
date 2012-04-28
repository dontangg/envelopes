require "bundler/capistrano"

server "money.thewilsonpad.com", :web, :app, :db, primary: true

set :application, "envelopes"
set :user, "app_user"
set :deploy_to, "/home/#{user}/apps/#{application}"

set :scm, :git
set :repository,  "git://github.com/dontangg/envelopes.git"
set :branch, "master"

# It complained about no tty, so use pty... no profile scripts :(
# http://weblog.jamisbuck.org/2007/10/14/capistrano-2-1
default_run_options[:pty] = true
ssh_options[:forward_agent] = true

# Don't show so much! (Log levels: IMPORTANT, INFO, DEBUG, TRACE, MAX_LEVEL)
logger.level = Capistrano::Logger::DEBUG

# Since we're using pty, load the path ourselves
#set :default_environment, {
#  "PATH" => "/home/app_user/.rbenv/shims:/home/app_user/.rbenv/bin:$PATH"
#}

after "deploy", "deploy:cleanup" # keep only the last 5 releases

desc "Just like desploy, but with restart2"
task :deploy2, roles: :app, except: { no_release: true } do
  deploy.update
  deploy.restart2
end

namespace :deploy do
  desc "Zero-downtime restart of Unicorn"
  task :restart, roles: :app, except: { no_release: true } do
    run "kill -s USR2 `cat /tmp/unicorn.envelopes.pid`"
  end

  desc "Restart Unicorn with downtime, but will take new gems into account"
  task :restart2, roles: :app, except: { no_release: true } do
    stop
    start
  end

  desc "Start Unicorn"
  task :start, roles: :app, except: { no_release: true } do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D"
  end

  desc "Stop Unicorn"
  task :stop, roles: :app, except: { no_release: true } do
    run "kill -s QUIT `cat /tmp/unicorn.envelopes.pid`"
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
  end
  after "deploy:setup", "deploy:setup_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless '`git cherry`'.empty?
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"

  namespace :assets do

    desc <<-DESC
      Run the asset precompilation rake task. You can specify the full path \
      to the rake executable by setting the rake variable. You can also \
      specify additional environment variables to pass to rake via the \
      asset_env variable. The defaults are:

        set :rake,      "rake"
        set :rails_env, "production"
        set :asset_env, "RAILS_GROUPS=assets"

      * only runs if assets have changed (add `-s force_assets=true` to force precompilation)
    DESC
    task :precompile, roles: :web, except: { no_release: true } do
      # Only precompile assets if any assets changed
      # http://www.bencurtis.com/2011/12/skipping-asset-compilation-with-capistrano/
      from = source.next_revision(current_revision)
      if fetch(:force_assets, false) || capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ lib/assets/ | wc -l").to_i > 0
        # Just like original: https://github.com/capistrano/capistrano/blob/master/lib/capistrano/recipes/deploy/assets.rb
        run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile"
      else
        logger.info "Skipping asset pre-compilation because there were no asset changes"
      end
    end

  end

end



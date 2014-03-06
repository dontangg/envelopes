# Documentation here: http://www.capistranorb.com/
# To setup access to a private repo, check under 'From our servers to the repository host' here: http://www.capistranorb.com/documentation/getting-started/authentication-and-authorisation/#toc_2

set :application, 'envelopes'
set :repo_url, 'git@github.com:dontangg/envelopes.git'

# To have it deploy the branch that you're currently on
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Always deploy master
set :branch, 'master'

set :deploy_to, '~/apps/envelopes'
set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

#set :linked_files, %w{config/newrelic.yml config/aws.yml}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :keep_releases, 5

# rbenv settings
#set :rbenv_type, :user # or :system, depends on your rbenv setup
#set :rbenv_ruby, '2.0.0-p247'
#set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
#set :rbenv_map_bins, %w{rake gem bundle ruby rails}
#set :rbenv_roles, :all # default value

namespace :deploy do

  desc 'Restart application'
  after :publishing, :restart do
    # This will run on all app servers 1 at a time waiting 5 seconds between each one
    on roles(:app), in: :sequence, wait: 5 do
      within current_path do
        pidfile = shared_path.join('pids', 'unicorn.pid')

        # if the pid file exists then we need to restart the server
        if test "[ -f #{pidfile} ]"
          execute :kill, "-USR2 `cat #{pidfile}`"
        else
          # start the server
          execute :bundle, "exec unicorn_rails -c config/unicorn.rb -D"
        end
      end
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Stop the application'
  task :stop do
    on roles(:app) do
      within current_path do
        pidfile = shared_path.join('pids', 'unicorn.pid')

        # if the pid file exists then we need to restart the server
        if test "[ -f #{pidfile} ]"
          execute :kill, "-QUIT `cat #{pidfile}`"
        end
      end
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end

  end

  desc 'Symlink the nginx conf file'
  after 'symlink:release', 'symlink:nginx' do
    # This will run on servers in groups of 3 and wait 10 seconds between groups
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      target = "/etc/nginx/sites-enabled/envelopes"
      source = current_path.join("config", "nginx.conf")
      unless test "[ -L #{target} ]"
        if test "[ -f #{target} ]"
          execute :rm, target
        end
        execute :ln, '-s', source, target
      end
    end
  end

  #after :restart, :clear_cache do
  #  on roles(:web), in: :groups, limit: 3, wait: 10 do
  #    # Here we can do anything such as:
  #    # within release_path do
  #    #   execute :rake, 'cache:clear'
  #    # end
  #  end
  #end

  after :finishing, :cleanup

end



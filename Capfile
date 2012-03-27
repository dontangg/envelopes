load 'deploy'
load 'deploy/assets' # Using Rails' asset pipeline
Dir['vendor/gems/*/recipes/*.rb','vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy' # Remove this line to skip loading any of the default tasks

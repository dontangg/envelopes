# This file is used by Rack-based servers to start the application.
$stdout.sync = true
require ::File.expand_path('../config/environment',  __FILE__)
use Rack::Deflater # Because the Heroku Cedar stack doesn't use nginx (http://devcenter.heroku.com/articles/http-routing#gzipped_responses)
run Envelopes::Application

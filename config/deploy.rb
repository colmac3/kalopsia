print "Deploy to (T)est or (S)taging [T]? "
choice = (((choice = $stdin.gets.downcase.chomp[0]).nil?) ? 't' : choice.chr)

require File.join(File.dirname(__FILE__), "deploy_credentials");

$credentials = DeployCredentials.new();
require 'yaml'
app_config = YAML::load(File.read(File.join(File.dirname(__FILE__), "deploy.yml")))

berylpw = $credentials.beryl_password
scm_username = $credentials.scm_username
scmpw = $credentials.scm_password
app_name = app_config['app_name']

case choice
  when 't'
    subdirectory = 'test'
    set :rails_env, 'development'
    subdomain = "test.#{app_name}"
  when 's'
    subdirectory = 'production'
    set :rails_env, 'staging'
    subdomain = app_name
  else raise ArgumentError, "Expected one of [t, s]"
end

app_path = File.join(app_config['base_path'], subdirectory, app_name)

puts "Deploying to #{subdomain}.berylapp.com..."
puts
puts "Press Enter to confirm, Control-C to cancel"
$stdin.gets

default_run_options[:pty] = true
default_environment['PATH'] = %w(
  /opt/rvm/rvm/gems/ree-1.8.7-2011.03/bin
  /opt/rvm/rvm/rubies/ree-1.8.7-2011.03/bin
  /opt/rvm/bin
  /usr/local/lib/git-core
  $PATH
).join(":")
ssh_options[:keys] = []
set :git_enable_submodules, 1
set :application, subdomain
set :deploy_to, app_path
set :repository, app_config['repo']
set :keep_releases, 3
set :use_sudo, false

set :scm, app_config['scm']
set :scm_username, scm_username
set :scm_password, scmpw

role :app, app_config['ip']
role :web, app_config['ip']
role :db,  app_config['ip'], :primary => true
set :user, app_config['user']
set :password, berylpw
set :deploy_via, :export

before "deploy:cold", "deploy:setup"
after "deploy:cold", "deploy:seed"

#after "deploy:update_code", "deploy:finalize_update"
after "deploy:update_code", "credentials:save"
after "deploy:migrate", "rtml:migrate"
after "deploy:migrate", "credentials:save"
#after "deploy:setup", "deploy:finalize_setup"
after "deploy:setup", "credentials:save"

# tasks


namespace :rtml do
  task :migrate do
    run "cd #{current_release} && /usr/bin/rake rtml:migrate RAILS_ENV=#{rails_env}"
  end

  task :setup do
    run "cd #{current_release} && /usr/bin/rake rtml:setup RAILS_ENV=#{rails_env}"
  end
end

namespace :deploy do
  task :seed do
    run "cd #{current_release} && /usr/bin/rake db:seed RAILS_ENV=#{rails_env}"
  end

  task :after_setup do
    run "mkdir #{app_path}/shared/cache"
  end

  task :after_update do
    # Get the database.yml file
    run "ln -sf #{app_path}/shared/config/database.yml #{current_release}/config/database.yml"

    # Create the base htaccess
    run "echo 'PassengerEnabled on' >#{release_path}/public/.htaccess"
    
    # Change the ApplicationRoot to point at the correct app root
    run "echo 'PassengerAppRoot #{release_path}' >>#{release_path}/public/.htaccess"

    # Run in production mode, unless the target was 'test'.
    run "echo 'RailsEnv #{rails_env}' >>#{release_path}/public/.htaccess"

    # If running in test mode, we'll need the previous deployment's sqlite file.
    if prv_db = ("#{previous_release}/db/development.sqlite3" rescue nil)
      run "[ -f #{prv_db} ] && cp #{prv_db} #{release_path}/db/development.sqlite3 || echo 'WARNING: Could not find database file #{prv_db}'"
    end

    # install bundle
    run "cd #{current_release}; bundle install --without production --path /home/berylapp/gems/ --local"
  end

  # override server restart for Phusion Passenger
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  # override server stop for Phusion Passenger
  task :stop, :roles => :app do
    # do nothing
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

namespace :credentials do
  task :save do
    $credentials.save
  end
end

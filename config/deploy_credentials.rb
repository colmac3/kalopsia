require 'rubygems'
require 'yaml'

class DeployCredentials
  attr_reader :beryl_password, :scm_username, :scm_password

  def initialize
    path = config_file_name
    if File.file?(path)
      yaml = (YAML::load(File.read(path)) rescue {})
      @beryl_password = yaml[:beryl_password]
      @scm_username = yaml[:scm_username]
      @scm_password = yaml[:scm_password]
    else
      @beryl_password = Capistrano::CLI.password_prompt('BerylApp password:')
      @scm_username = Capistrano::CLI.ui.ask("SVN username:")
      @scm_password = Capistrano::CLI.password_prompt("SVN password:")
    end
  end

  def save
    File.open(config_file_name, "w") do |file|
      file.puts({
        :beryl_password => @beryl_password,
        :scm_username => @scm_username,
        :scm_password => @scm_password  
      }.to_yaml)
    end
  end

  private
  def config_file_name
    home = ENV['HOME'] || ENV['USERPROFILE']
    if home.is_a?(String) && home.length != 0
      return File.join(home, ".capdeploy")
    else
      return nil
    end
  end
end

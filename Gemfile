source :gemcutter

gem "rails", "= 2.3.8"
gem 'rack', '= 1.1.0'
gem 'rest-client', '= 1.6.7'

group :production do
  gem "SyslogLogger", "~> 1.4.0"
  gem "pg", "= 0.9.0"
end

gem 'savon'

gem "hpricot", "~> 0.8.4"
group :development, :test, :cucumber do
  gem "mysql"
  gem 'capistrano', "~> 2.5.20"
  gem 'test-unit', '~> 1.2.3'
end

group :cucumber do
  gem 'cucumber-rails',   '~> 0.2.4', :require => false
  gem 'database_cleaner', '~> 0.4.3', :require => false
  gem 'webrat',           '~> 0.6.0', :require => false
  gem 'rspec',            '~> 1.3.0', :require => false
  gem 'rspec-rails',      '~> 1.3.2', :require => false
  gem 'ruby-prof',                    :require => false
end

group :test do
  gem 'rspec',       "~> 1.3.0",  :require => false
  gem 'rspec-rails', '~> 1.3.2', :require => false
end

require 'fileutils'

plugin_root = File.dirname(__FILE__)

# copy rpm spec template to rails config dir
FileUtils.cp(File.join(plugin_root, 'rpm-specs', 'application.spec'),
             File.join(RAILS_ROOT, 'config'))

FileUtils.mkdir_p(File.join(RAILS_ROOT, "system-files"))
FileUtils.cp(File.join(plugin_root, 'system-files', 'application.conf'),
	     File.join(RAILS_ROOT, 'system-files'))


namespace :rpm do

  BUILD_DIR = File.join(RAILS_ROOT, "build")

  desc  "build rpm package"
  task :build do
    spec_file_name = %x[find ./config -name '*.spec']
    spec = File.new(spec_file_name.strip!, "r").read

    match_name = spec.match(/Name:\s*(\w*)/)
    name = match_name.captures.pop if match_name

    match_version = spec.match(/Version:\s*(.*)/)
    version = match_version.captures.pop if match_version

    archive_dir = File.join(BUILD_DIR, "#{name}-#{version}")

    FileUtils.mkdir_p archive_dir
    %w(BUILD RPMS SOURCES SPECS SRPMS).each do |d|
      FileUtils.mkdir_p File.join(BUILD_DIR, "rpm", d)
    end

    # rails dir
    FileUtils.mkdir_p "#{archive_dir}/rails"
    rails_files =
      %w(app db lib public config doc Rakefile script vendor)
    system "cp -aR #{rails_files.join(" ")} #{archive_dir}/rails"

    # system files
    FileUtils.mkdir_p "#{archive_dir}/system-files"
    system "cp -aR system-files/* #{archive_dir}/system-files"

    tar_file = "#{BUILD_DIR}/rpm/SOURCES/#{name}-#{version}.tar.gz"
    system "tar -czvpf #{tar_file} -C build #{name}-#{version}"

    system "rpmbuild -ba --define '_topdir #{BUILD_DIR}/rpm' --clean #{spec_file_name}"
  end

  desc "clean up"
  task :clean do
    system "rm -rf #{BUILD_DIR}/*"
  end
end

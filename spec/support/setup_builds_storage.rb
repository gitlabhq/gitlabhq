RSpec.configure do |config|
  def builds_path
    Rails.root.join('tmp/builds')
  end

  config.before(:each) do
    FileUtils.mkdir_p(builds_path)
    FileUtils.touch(File.join(builds_path, ".gitkeep"))
    Settings.gitlab_ci['builds_path'] = builds_path
  end

  config.after(:suite) do
    Dir[File.join(builds_path, '*')].each do |path|
      next if File.basename(path) == '.gitkeep'

      FileUtils.rm_rf(path)
    end
  end
end

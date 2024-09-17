# frozen_string_literal: true

RSpec.configure do |config|
  def builds_path
    Rails.root.join('tmp/tests/builds').to_s
  end

  config.before(:suite) do
    Settings.gitlab_ci['builds_path'] = builds_path
  end

  config.before(:all) do
    FileUtils.mkdir_p(builds_path)
  end

  config.before do
    FileUtils.rm_rf(builds_path)
    FileUtils.mkdir_p(builds_path)
  end
end

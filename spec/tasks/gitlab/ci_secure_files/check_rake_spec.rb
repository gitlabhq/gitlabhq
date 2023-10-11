# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:ci_secure_files', factory_default: :keep, feature_category: :mobile_devops do
  describe 'check' do
    let!(:project) { create_default(:project).freeze }
    let!(:secure_file) { create(:ci_secure_file) }

    before do
      Rake.application.rake_require('tasks/gitlab/ci_secure_files/check')
      stub_env('VERBOSE' => 'true')
    end

    it 'outputs the integrity check for each batch' do
      expect { run_rake_task('gitlab:ci_secure_files:check') }.to output(/Failures: 0/).to_stdout
    end

    it 'errors out about missing files on the file system' do
      FileUtils.rm_f(secure_file.file.path)

      expect do
        run_rake_task('gitlab:ci_secure_files:check')
      end.to output(/No such file.*#{Regexp.quote(secure_file.file.path)}/).to_stdout
    end

    it 'errors out about invalid checksum' do
      secure_file.update_column(:checksum, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855')

      expect { run_rake_task('gitlab:ci_secure_files:check') }.to output(/Checksum mismatch/).to_stdout
    end
  end
end

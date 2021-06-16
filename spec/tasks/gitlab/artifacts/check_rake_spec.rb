# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:artifacts rake tasks', :silence_stdout do
  describe 'check' do
    let!(:artifact) { create(:ci_job_artifact, :archive, :correct_checksum) }

    before do
      Rake.application.rake_require('tasks/gitlab/artifacts/check')
      stub_env('VERBOSE' => 'true')
    end

    it 'outputs the integrity check for each batch' do
      expect { run_rake_task('gitlab:artifacts:check') }.to output(/Failures: 0/).to_stdout
    end

    it 'errors out about missing files on the file system' do
      FileUtils.rm_f(artifact.file.path)

      expect { run_rake_task('gitlab:artifacts:check') }.to output(/No such file.*#{Regexp.quote(artifact.file.path)}/).to_stdout
    end

    it 'errors out about invalid checksum' do
      artifact.update_column(:file_sha256, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855')

      expect { run_rake_task('gitlab:artifacts:check') }.to output(/Checksum mismatch/).to_stdout
    end

    it 'errors out about missing checksum' do
      artifact.update_column(:file_sha256, nil)

      expect { run_rake_task('gitlab:artifacts:check') }.to output(/Checksum missing/).to_stdout
    end
  end
end

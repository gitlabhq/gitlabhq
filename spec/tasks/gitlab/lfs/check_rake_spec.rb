# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:lfs rake tasks', :silence_stdout do
  describe 'check' do
    let!(:lfs_object) { create(:lfs_object, :with_file, :correct_oid) }

    before do
      Rake.application.rake_require('tasks/gitlab/lfs/check')
      stub_env('VERBOSE' => 'true')
    end

    it 'outputs the integrity check for each batch' do
      expect { run_rake_task('gitlab:lfs:check') }.to output(/Failures: 0/).to_stdout
    end

    it 'errors out about missing files on the file system' do
      FileUtils.rm_f(lfs_object.file.path)

      expect { run_rake_task('gitlab:lfs:check') }.to output(/No such file.*#{Regexp.quote(lfs_object.file.path)}/).to_stdout
    end

    it 'errors out about invalid checksum' do
      File.truncate(lfs_object.file.path, 0)

      expect { run_rake_task('gitlab:lfs:check') }.to output(/Checksum mismatch/).to_stdout
    end
  end
end

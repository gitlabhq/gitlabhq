# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:uploads rake tasks', :silence_stdout do
  describe 'check' do
    let!(:upload) { create(:upload, path: Rails.root.join('spec/fixtures/banana_sample.gif')) }

    before do
      Rake.application.rake_require('tasks/gitlab/uploads/check')
      stub_env('VERBOSE' => 'true')
    end

    it 'outputs the integrity check for each batch' do
      expect { run_rake_task('gitlab:uploads:check') }.to output(/Failures: 0/).to_stdout
    end

    it 'errors out about missing files on the file system' do
      missing_upload = create(:upload)

      expect { run_rake_task('gitlab:uploads:check') }.to output(/No such file.*#{Regexp.quote(missing_upload.absolute_path)}/).to_stdout
    end

    it 'errors out about invalid checksum' do
      upload.update_column(:checksum, '01a3156db2cf4f67ec823680b40b7302f89ab39179124ad219f94919b8a1769e')

      expect { run_rake_task('gitlab:uploads:check') }.to output(/Checksum mismatch/).to_stdout
    end
  end
end

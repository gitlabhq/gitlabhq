# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:service_desk_email:secret rake tasks', :silence_stdout, feature_category: :build do
  let(:encrypted_secret_file_dir) { Pathname.new(Dir.mktmpdir) }
  let(:encrypted_secret_file) { encrypted_secret_file_dir.join('service_desk_email.yaml.enc') }

  before do
    Rake.application.rake_require 'tasks/gitlab/service_desk_email'
    stub_env('EDITOR', 'cat')
    stub_warn_user_is_not_gitlab
    FileUtils.mkdir_p('tmp/tests/service_desk_email_enc/')
    allow(Gitlab.config.service_desk_email).to receive(:encrypted_secret_file).and_return(encrypted_secret_file)
    allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
  end

  after do
    FileUtils.rm_rf(Rails.root.join('tmp/tests/service_desk_email_enc'))
  end

  describe ':show' do
    it 'displays error when file does not exist' do
      expect { run_rake_task('gitlab:service_desk_email:secret:show') }.to \
        output(/File .* does not exist. Use `gitlab-rake gitlab:service_desk_email:secret:edit` to change that./) \
        .to_stdout
    end

    it 'displays error when key does not exist' do
      Settings.encrypted(encrypted_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect { run_rake_task('gitlab:service_desk_email:secret:show') }.to \
        output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when key is changed' do
      Settings.encrypted(encrypted_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
      expect { run_rake_task('gitlab:service_desk_email:secret:show') }.to \
        output(/Couldn't decrypt .* Perhaps you passed the wrong key?/).to_stderr
    end

    it 'outputs the unencrypted content when present' do
      encrypted = Settings.encrypted(encrypted_secret_file)
      encrypted.write('somevalue')
      expect { run_rake_task('gitlab:service_desk_email:secret:show') }.to output(/somevalue/).to_stdout
    end
  end

  describe 'edit' do
    it 'creates encrypted file' do
      expect { run_rake_task('gitlab:service_desk_email:secret:edit') }.to \
        output(/File encrypted and saved./).to_stdout
      expect(File.exist?(encrypted_secret_file)).to be true
      value = Settings.encrypted(encrypted_secret_file)
      expect(value.read).to match(/password: '123'/)
    end

    it 'displays error when key does not exist' do
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect { run_rake_task('gitlab:service_desk_email:secret:edit') }.to \
        output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when key is changed' do
      Settings.encrypted(encrypted_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
      expect { run_rake_task('gitlab:service_desk_email:secret:edit') }.to \
        output(/Couldn't decrypt .* Perhaps you passed the wrong key?/).to_stderr
    end

    it 'displays error when write directory does not exist' do
      FileUtils.rm_rf(encrypted_secret_file_dir)
      expect { run_rake_task('gitlab:service_desk_email:secret:edit') }.to \
        output(/Directory .* does not exist./).to_stderr
    end

    it 'shows a warning when content is invalid' do
      Settings.encrypted(encrypted_secret_file).write('somevalue')
      expect { run_rake_task('gitlab:service_desk_email:secret:edit') }.to \
        output(/WARNING: Content was not a valid SERVICE_DESK_EMAIL secret yml file/).to_stdout
      value = Settings.encrypted(encrypted_secret_file)
      expect(value.read).to match(/somevalue/)
    end

    it 'displays error when $EDITOR is not set' do
      stub_env('EDITOR', nil)
      expect { run_rake_task('gitlab:service_desk_email:secret:edit') }.to \
        output(/No \$EDITOR specified to open file. Please provide one when running the command/).to_stderr
    end
  end

  describe 'write' do
    before do
      allow($stdin).to receive(:tty?).and_return(false)
      allow($stdin).to receive(:read).and_return('username: foo')
    end

    it 'creates encrypted file from stdin' do
      expect { run_rake_task('gitlab:service_desk_email:secret:write') }.to \
        output(/File encrypted and saved./).to_stdout
      expect(File.exist?(encrypted_secret_file)).to be true
      value = Settings.encrypted(encrypted_secret_file)
      expect(value.read).to match(/username: foo/)
    end

    it 'displays error when key does not exist' do
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect { run_rake_task('gitlab:service_desk_email:secret:write') }.to \
        output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when write directory does not exist' do
      FileUtils.rm_rf(encrypted_secret_file_dir)
      expect { run_rake_task('gitlab:service_desk_email:secret:write') }.to \
        output(/Directory .* does not exist./).to_stderr
    end

    it 'shows a warning when content is invalid' do
      Settings.encrypted(encrypted_secret_file).write('somevalue')
      expect { run_rake_task('gitlab:service_desk_email:secret:edit') }.to \
        output(/WARNING: Content was not a valid SERVICE_DESK_EMAIL secret yml file/).to_stdout
      value = Settings.encrypted(encrypted_secret_file)
      expect(value.read).to match(/somevalue/)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:smtp:secret rake tasks' do
  let(:smtp_secret_file) { 'tmp/tests/smtpenc/smtp_secret.yaml.enc' }

  before do
    Rake.application.rake_require 'tasks/gitlab/smtp'
    stub_env('EDITOR', 'cat')
    stub_warn_user_is_not_gitlab
    FileUtils.mkdir_p('tmp/tests/smtpenc/')
    allow(Gitlab.config.gitlab).to receive(:email_smtp_secret_file).and_return(smtp_secret_file)
    allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
  end

  after do
    FileUtils.rm_rf(Rails.root.join('tmp/tests/smtpenc'))
  end

  describe ':show' do
    it 'displays error when file does not exist' do
      expect do
        run_rake_task('gitlab:smtp:secret:show')
      end.to output(/File .* does not exist. Use `gitlab-rake gitlab:smtp:secret:edit` to change that./).to_stdout
    end

    it 'displays error when key does not exist' do
      Settings.encrypted(smtp_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect do
        run_rake_task('gitlab:smtp:secret:show')
      end.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when key is changed' do
      Settings.encrypted(smtp_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
      expect do
        run_rake_task('gitlab:smtp:secret:show')
      end.to output(/Couldn't decrypt .* Perhaps you passed the wrong key?/).to_stderr
    end

    it 'outputs the unencrypted content when present' do
      encrypted = Settings.encrypted(smtp_secret_file)
      encrypted.write('somevalue')
      expect { run_rake_task('gitlab:smtp:secret:show') }.to output(/somevalue/).to_stdout
    end
  end

  describe 'edit' do
    it 'creates encrypted file' do
      expect { run_rake_task('gitlab:smtp:secret:edit') }.to output(/File encrypted and saved./).to_stdout
      expect(File.exist?(smtp_secret_file)).to be true
      value = Settings.encrypted(smtp_secret_file)
      expect(value.read).to match(/password: '123'/)
    end

    it 'displays error when key does not exist' do
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect do
        run_rake_task('gitlab:smtp:secret:edit')
      end.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when key is changed' do
      Settings.encrypted(smtp_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
      expect do
        run_rake_task('gitlab:smtp:secret:edit')
      end.to output(/Couldn't decrypt .* Perhaps you passed the wrong key?/).to_stderr
    end

    it 'displays error when write directory does not exist' do
      FileUtils.rm_rf(Rails.root.join('tmp/tests/smtpenc'))
      expect { run_rake_task('gitlab:smtp:secret:edit') }.to output(/Directory .* does not exist./).to_stderr
    end

    it 'shows a warning when content is invalid' do
      Settings.encrypted(smtp_secret_file).write('somevalue')
      expect { run_rake_task('gitlab:smtp:secret:edit') }.to output(/WARNING: Content was not a valid SMTP secret yml file/).to_stdout
      value = Settings.encrypted(smtp_secret_file)
      expect(value.read).to match(/somevalue/)
    end

    it 'displays error when $EDITOR is not set' do
      stub_env('EDITOR', nil)
      expect { run_rake_task('gitlab:smtp:secret:edit') }.to output(/No \$EDITOR specified to open file. Please provide one when running the command/).to_stderr
    end
  end

  describe 'write' do
    before do
      allow($stdin).to receive(:tty?).and_return(false)
      allow($stdin).to receive(:read).and_return('username: foo')
    end

    it 'creates encrypted file from stdin' do
      expect { run_rake_task('gitlab:smtp:secret:write') }.to output(/File encrypted and saved./).to_stdout
      expect(File.exist?(smtp_secret_file)).to be true
      value = Settings.encrypted(smtp_secret_file)
      expect(value.read).to match(/username: foo/)
    end

    it 'displays error when key does not exist' do
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect do
        run_rake_task('gitlab:smtp:secret:write')
      end.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when write directory does not exist' do
      FileUtils.rm_rf('tmp/tests/smtpenc/')
      expect { run_rake_task('gitlab:smtp:secret:write') }.to output(/Directory .* does not exist./).to_stderr
    end

    it 'shows a warning when content is invalid' do
      Settings.encrypted(smtp_secret_file).write('somevalue')
      expect { run_rake_task('gitlab:smtp:secret:edit') }.to output(/WARNING: Content was not a valid SMTP secret yml file/).to_stdout
      value = Settings.encrypted(smtp_secret_file)
      expect(value.read).to match(/somevalue/)
    end
  end
end

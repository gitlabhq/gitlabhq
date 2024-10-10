# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:redis:secret rake tasks', :silence_stdout, feature_category: :build do
  let(:redis_secret_file) { 'tmp/tests/redisenc/redis_secret.yaml.enc' }

  before do
    Rake.application.rake_require 'tasks/gitlab/redis'
    stub_env('EDITOR', 'cat')
    stub_warn_user_is_not_gitlab
    FileUtils.mkdir_p('tmp/tests/redisenc/')
    allow(::Gitlab::Runtime).to receive(:rake?).and_return(true)
    allow_next_instance_of(Gitlab::Redis::Cache) do |instance|
      allow(instance).to receive(:secret_file).and_return(redis_secret_file)
    end
    allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
  end

  after do
    FileUtils.rm_rf(Rails.root.join('tmp/tests/redisenc'))
  end

  describe ':show' do
    it 'displays error when file does not exist' do
      expect do
        run_rake_task('gitlab:redis:secret:show')
      end.to output(/File .* does not exist. Use `gitlab-rake gitlab:redis:secret:edit` to change that./).to_stdout
    end

    it 'displays error when key does not exist' do
      Settings.encrypted(redis_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect do
        run_rake_task('gitlab:redis:secret:show')
      end.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when key is changed' do
      Settings.encrypted(redis_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
      expect do
        run_rake_task('gitlab:redis:secret:show')
      end.to output(/Couldn't decrypt .* Perhaps you passed the wrong key?/).to_stderr
    end

    it 'outputs the unencrypted content when present' do
      encrypted = Settings.encrypted(redis_secret_file)
      encrypted.write('somevalue')
      expect { run_rake_task('gitlab:redis:secret:show') }.to output(/somevalue/).to_stdout
    end
  end

  describe 'edit' do
    it 'creates encrypted file' do
      expect { run_rake_task('gitlab:redis:secret:edit') }.to output(/File encrypted and saved./).to_stdout
      expect(File.exist?(redis_secret_file)).to be true
      value = Settings.encrypted(redis_secret_file)
      expect(value.read).to match(/password: '123'/)
    end

    it 'displays error when key does not exist' do
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect do
        run_rake_task('gitlab:redis:secret:edit')
      end.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when key is changed' do
      Settings.encrypted(redis_secret_file).write('somevalue')
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(SecureRandom.hex(64))
      expect do
        run_rake_task('gitlab:redis:secret:edit')
      end.to output(/Couldn't decrypt .* Perhaps you passed the wrong key?/).to_stderr
    end

    it 'displays error when write directory does not exist' do
      FileUtils.rm_rf(Rails.root.join('tmp/tests/redisenc'))
      expect { run_rake_task('gitlab:redis:secret:edit') }.to output(/Directory .* does not exist./).to_stderr
    end

    it 'shows a warning when content is invalid' do
      Settings.encrypted(redis_secret_file).write('somevalue')
      expect do
        run_rake_task('gitlab:redis:secret:edit')
      end.to output(/WARNING: Content was not a valid Redis secret yml file/).to_stdout
      value = Settings.encrypted(redis_secret_file)
      expect(value.read).to match(/somevalue/)
    end

    it 'displays error when $EDITOR is not set' do
      stub_env('EDITOR', nil)
      expect do
        run_rake_task('gitlab:redis:secret:edit')
      end.to output(/No \$EDITOR specified to open file. Please provide one when running the command/).to_stderr
    end
  end

  describe 'write' do
    before do
      allow($stdin).to receive(:tty?).and_return(false)
      allow($stdin).to receive(:read).and_return('testvalue')
    end

    it 'creates encrypted file from stdin' do
      expect { run_rake_task('gitlab:redis:secret:write') }.to output(/File encrypted and saved./).to_stdout
      expect(File.exist?(redis_secret_file)).to be true
      value = Settings.encrypted(redis_secret_file)
      expect(value.read).to match(/testvalue/)
    end

    it 'displays error when key does not exist' do
      allow(Gitlab::Application.credentials).to receive(:encrypted_settings_key_base).and_return(nil)
      expect do
        run_rake_task('gitlab:redis:secret:write')
      end.to output(/Missing encryption key encrypted_settings_key_base./).to_stderr
    end

    it 'displays error when write directory does not exist' do
      FileUtils.rm_rf('tmp/tests/redisenc/')
      expect { run_rake_task('gitlab:redis:secret:write') }.to output(/Directory .* does not exist./).to_stderr
    end

    it 'shows a warning when content is invalid' do
      Settings.encrypted(redis_secret_file).write('somevalue')
      expect do
        run_rake_task('gitlab:redis:secret:edit')
      end.to output(/WARNING: Content was not a valid Redis secret yml file/).to_stdout
      expect(Settings.encrypted(redis_secret_file).read).to match(/somevalue/)
    end
  end

  context 'when an instance class is specified' do
    before do
      allow_next_instance_of(Gitlab::Redis::SharedState) do |instance|
        allow(instance).to receive(:secret_file).and_return(redis_secret_file)
      end
    end

    context 'when actual name is used' do
      it 'uses the correct Redis class' do
        expect(Gitlab::Redis::SharedState).to receive(:encrypted_secrets).and_call_original

        run_rake_task('gitlab:redis:secret:edit', 'SharedState')
      end
    end

    context 'when name in lowercase is used' do
      it 'uses the correct Redis class' do
        expect(Gitlab::Redis::SharedState).to receive(:encrypted_secrets).and_call_original

        run_rake_task('gitlab:redis:secret:edit', 'sharedstate')
      end
    end

    context 'when name with underscores is used' do
      it 'uses the correct Redis class' do
        expect(Gitlab::Redis::SharedState).to receive(:encrypted_secrets).and_call_original

        run_rake_task('gitlab:redis:secret:edit', 'shared_state')
      end
    end

    context 'when name with hyphens is used' do
      it 'uses the correct Redis class' do
        expect(Gitlab::Redis::SharedState).to receive(:encrypted_secrets).and_call_original

        run_rake_task('gitlab:redis:secret:edit', 'shared-state')
      end
    end

    context 'when name with spaces is used' do
      it 'uses the correct Redis class' do
        expect(Gitlab::Redis::SharedState).to receive(:encrypted_secrets).and_call_original

        run_rake_task('gitlab:redis:secret:edit', 'shared state')
      end
    end

    context 'when an invalid name is used' do
      it 'raises error' do
        expect do
          run_rake_task('gitlab:redis:secret:edit', 'foobar')
        end.to raise_error(/Specified instance name foobar does not exist./)
      end
    end
  end
end

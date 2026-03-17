# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:workhorse namespace rake task', :silence_stdout, feature_category: :source_code_management do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/workhorse'
  end

  describe 'install' do
    let(:repo) { 'https://gitlab.com/gitlab-org/gitlab-workhorse.git' }
    let(:clone_path) { Dir.mktmpdir('gitlab:workhorse:install-rake-test') }
    let(:workhorse_source) { Rails.root.join('workhorse').to_s }

    after do
      FileUtils.rm_rf(clone_path)
    end

    context 'no dir given' do
      it 'aborts and display a help message' do
        # avoid writing task output to spec progress
        allow($stderr).to receive :write
        expect { run_rake_task('gitlab:workhorse:install') }.to raise_error(/Please specify the directory where you want to install gitlab-workhorse/)
      end
    end

    context 'when an underlying Git command fails' do
      it 'aborts and display a help message' do
        expect(main_object)
          .to receive(:checkout_or_clone_version).and_raise 'Git error'

        expect { run_rake_task('gitlab:workhorse:install', clone_path) }.to raise_error 'Git error'
      end
    end

    it 'clones the repo and compiles workhorse' do
      expect(main_object)
        .to receive(:checkout_or_clone_version)
        .with(
          version: 'workhorse-move-notice',
          repo: 'https://gitlab.com/gitlab-org/gitlab-workhorse.git',
          target_dir: clone_path,
          clone_opts: %w[--depth 1]
        )

      expect(Gitlab::SetupHelper::Workhorse)
        .to receive(:compile_into)
        .with(clone_path)

      run_rake_task('gitlab:workhorse:install', clone_path)
    end
  end
end

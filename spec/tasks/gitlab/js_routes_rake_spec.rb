# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:js:routes rake tasks', feature_category: :tooling do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/js_routes'
  end

  before do
    # match_ci_env! re-execs the process unless it detects CI's invocation
    # context. Point GITLAB_CONFIG at the canonical config so the guard returns
    # early; otherwise the exec replaces the rspec process and aborts the run.
    stub_env('GITLAB_CONFIG' => Rails.root.join('config/gitlab.yml.example').to_s)
  end

  describe 'gitlab:js:routes' do
    before do
      allow(Gitlab::JsRoutes).to receive(:generate!).and_return('')
    end

    subject(:rake_task) { run_rake_task('gitlab:js:routes') }

    it 'calls Gitlab::JsRoutes#generate!' do
      expect(Gitlab::JsRoutes).to receive(:generate!)

      rake_task
    end
  end

  describe 'gitlab:js:routes:updated_check' do
    before do
      allow(Gitlab::JsRoutes).to receive(:generate!)
    end

    subject(:rake_task) { run_rake_task('gitlab:js:routes:updated_check') }

    def stub_git(diff: '', untracked: '')
      allow(Gitlab::Popen).to receive(:popen).and_return(['', 0])
      allow(Gitlab::Popen).to receive(:popen)
        .with(array_including('diff')).and_return([diff, 0])
      allow(Gitlab::Popen).to receive(:popen)
        .with(array_including('ls-files')).and_return([untracked, 0])
    end

    it 'regenerates path helpers' do
      stub_git

      expect(Gitlab::JsRoutes).to receive(:generate!)

      rake_task
    end

    context 'when generated output matches the committed tree' do
      before do
        stub_git
      end

      it 'does not raise' do
        expect { rake_task }.not_to raise_error
      end
    end

    context 'when regeneration produces a diff against tracked files' do
      before do
        stub_git(diff: "diff --git a/app/.../foo.js b/app/.../foo.js\n+new line")
      end

      it 'raises with the regeneration instructions' do
        expect { rake_task }.to raise_error do |error|
          expect(error.message).to include('JavaScript path helpers are out of sync with Rails routes.')
          expect(error.message).to include('bin/rake gitlab:js:routes')
        end
      end
    end

    context 'when regeneration produces new untracked files' do
      before do
        stub_git(untracked: "app/assets/javascripts/lib/utils/path_helpers/new_namespace.js")
      end

      it 'raises with the regeneration instructions' do
        expect { rake_task }.to raise_error do |error|
          expect(error.message).to include('JavaScript path helpers are out of sync with Rails routes.')
          expect(error.message).to include('bin/rake gitlab:js:routes')
        end
      end
    end
  end
end

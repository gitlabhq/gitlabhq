# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:env:info', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/info'

    stub_warn_user_is_not_gitlab
    allow(Gitlab::Popen).to receive(:popen)
  end

  describe 'git version' do
    before do
      allow(Gitlab::Popen).to receive(:popen).with([Gitlab.config.git.bin_path, '--version'])
        .and_return(git_version)
    end

    context 'when git installed' do
      let(:git_version) { 'git version 2.10.0' }

      it 'prints git version' do
        run_rake_task('gitlab:env:info')

        expect($stdout.string).to match(/Git Version:(.*)2.10.0/)
      end
    end

    context 'when git not installed' do
      let(:git_version) { '' }

      it 'prints unknown' do
        run_rake_task('gitlab:env:info')

        expect($stdout.string).to match(/Git Version:(.*)unknown/)
      end
    end
  end
end

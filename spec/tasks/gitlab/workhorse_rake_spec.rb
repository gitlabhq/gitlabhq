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

    it 'clones the origin and creates a gitlab-workhorse binary' do
      FileUtils.rm_rf(clone_path)

      Dir.mktmpdir('fake-workhorse-origin') do |workhorse_origin|
        [
          %W[git init -q #{workhorse_origin}],
          %W[git -C #{workhorse_origin} checkout -q -b workhorse-move-notice],
          %W[touch #{workhorse_origin}/proof-that-repo-got-cloned],
          %W[git -C #{workhorse_origin} add .],
          %W[git -C #{workhorse_origin} commit -q -m init],
          %W[git -C #{workhorse_origin} checkout -q -b master]
        ].each do |cmd|
          raise "#{cmd.join(' ')} failed" unless system(*cmd)
        end

        run_rake_task('gitlab:workhorse:install', clone_path, File.join(workhorse_origin, '.git'))
      end

      expect(File.exist?(File.join(clone_path, 'proof-that-repo-got-cloned'))).to be true
      expect(File.executable?(File.join(clone_path, 'gitlab-workhorse'))).to be true
    end
  end
end

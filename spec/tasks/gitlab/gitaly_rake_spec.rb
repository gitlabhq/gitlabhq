# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:gitaly namespace rake task', :silence_stdout do
  before :all do
    Rake.application.rake_require 'tasks/gitlab/gitaly'
  end

  describe 'install' do
    let(:repo) { 'https://gitlab.com/gitlab-org/gitaly.git' }
    let(:clone_path) { Rails.root.join('tmp/tests/gitaly').to_s }
    let(:storage_path) { Rails.root.join('tmp/tests/repositories').to_s }
    let(:version) { File.read(Rails.root.join(Gitlab::GitalyClient::SERVER_VERSION_FILE)).chomp }

    subject { run_rake_task('gitlab:gitaly:install', clone_path, storage_path) }

    context 'no dir given' do
      it 'aborts and display a help message' do
        # avoid writing task output to spec progress
        allow($stderr).to receive :write
        expect { run_rake_task('gitlab:gitaly:install') }.to raise_error /Please specify the directory where you want to install gitaly and the path for the default storage/
      end
    end

    context 'no storage path given' do
      it 'aborts and display a help message' do
        allow($stderr).to receive :write
        expect { run_rake_task('gitlab:gitaly:install', clone_path) }.to raise_error /Please specify the directory where you want to install gitaly and the path for the default storage/
      end
    end

    context 'when an underlying Git command fail' do
      it 'aborts and display a help message' do
        expect(main_object)
          .to receive(:checkout_or_clone_version).and_raise 'Git error'

        expect { subject }.to raise_error 'Git error'
      end
    end

    describe 'checkout or clone' do
      before do
        stub_env('CI', false)
        expect(Dir).to receive(:chdir).with(clone_path)
      end

      it 'calls checkout_or_clone_version with the right arguments' do
        expect(main_object)
          .to receive(:checkout_or_clone_version).with(version: version, repo: repo, target_dir: clone_path, clone_opts: %w[--depth 1])

        subject
      end
    end

    describe 'gmake/make' do
      before do
        stub_env('CI', false)
        FileUtils.mkdir_p(clone_path)
        expect(Dir).to receive(:chdir).with(clone_path).and_call_original
        stub_rails_env('development')
      end

      context 'gmake is available' do
        before do
          expect(main_object).to receive(:checkout_or_clone_version)
        end

        it 'calls gmake in the gitaly directory' do
          expect(Gitlab::Popen).to receive(:popen).with(%w[which gmake]).and_return(['/usr/bin/gmake', 0])
          expect(Gitlab::Popen).to receive(:popen).with(%w[gmake], nil, { "BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil }).and_return(true)

          subject
        end
      end

      context 'gmake is not available' do
        before do
          expect(main_object).to receive(:checkout_or_clone_version)
          expect(Gitlab::Popen).to receive(:popen).with(%w[which gmake]).and_return(['', 42])
        end

        it 'calls make in the gitaly directory' do
          expect(Gitlab::Popen).to receive(:popen).with(%w[make], nil, { "BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil }).and_return(true)

          subject
        end

        context 'when Rails.env is test' do
          let(:command) { %w[make] }

          before do
            stub_rails_env('test')
          end

          it 'calls make in the gitaly directory with BUNDLE_DEPLOYMENT and GEM_HOME variables' do
            expect(Gitlab::Popen).to receive(:popen).with(command, nil, { "BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil, "BUNDLE_DEPLOYMENT" => 'false', "GEM_HOME" => Bundler.bundle_path.to_s }).and_return(true)

            subject
          end
        end
      end
    end
  end
end

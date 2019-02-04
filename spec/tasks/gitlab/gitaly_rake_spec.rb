require 'rake_helper'

describe 'gitlab:gitaly namespace rake task' do
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
        expect(Dir).to receive(:chdir).with(clone_path)
      end

      it 'calls checkout_or_clone_version with the right arguments' do
        expect(main_object)
          .to receive(:checkout_or_clone_version).with(version: version, repo: repo, target_dir: clone_path)

        subject
      end
    end

    describe 'gmake/make' do
      let(:command_preamble) { %w[/usr/bin/env -u RUBYOPT -u BUNDLE_GEMFILE] }

      before do
        stub_env('CI', false)
        FileUtils.mkdir_p(clone_path)
        expect(Dir).to receive(:chdir).with(clone_path).and_call_original
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      context 'gmake is available' do
        before do
          expect(main_object).to receive(:checkout_or_clone_version)
        end

        it 'calls gmake in the gitaly directory' do
          expect(Gitlab::Popen).to receive(:popen).with(%w[which gmake]).and_return(['/usr/bin/gmake', 0])
          expect(main_object).to receive(:run_command!).with(command_preamble + %w[gmake]).and_return(true)

          subject
        end
      end

      context 'gmake is not available' do
        before do
          expect(main_object).to receive(:checkout_or_clone_version)
          expect(Gitlab::Popen).to receive(:popen).with(%w[which gmake]).and_return(['', 42])
        end

        it 'calls make in the gitaly directory' do
          expect(main_object).to receive(:run_command!).with(command_preamble + %w[make]).and_return(true)

          subject
        end

        context 'when Rails.env is test' do
          let(:command) do
            %W[make
               BUNDLE_FLAGS=--no-deployment
               BUNDLE_PATH=#{Bundler.bundle_path}]
          end

          before do
            allow(Rails.env).to receive(:test?).and_return(true)
          end

          it 'calls make in the gitaly directory with --no-deployment flag for bundle' do
            expect(main_object).to receive(:run_command!).with(command_preamble + command).and_return(true)

            subject
          end
        end
      end
    end
  end
end

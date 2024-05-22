# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:gitaly namespace rake task', :silence_stdout, feature_category: :source_code_management do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/gitaly'
  end

  let(:repo) { 'https://gitlab.com/gitlab-org/gitaly.git' }
  let(:clone_path) { Rails.root.join('tmp/tests/gitaly').to_s }
  let(:storage_path) { Rails.root.join('tmp/tests/repositories').to_s }
  let(:version) { File.read(Rails.root.join(Gitlab::GitalyClient::SERVER_VERSION_FILE)).chomp }

  describe 'clone' do
    subject { run_rake_task('gitlab:gitaly:clone', clone_path, storage_path) }

    context 'no dir given' do
      it 'aborts and display a help message' do
        # avoid writing task output to spec progress
        allow($stderr).to receive :write
        expect { run_rake_task('gitlab:gitaly:clone') }.to raise_error(/Please specify the directory where you want to install gitaly and the path for the default storage/)
      end
    end

    context 'no storage path given' do
      it 'aborts and display a help message' do
        allow($stderr).to receive :write
        expect { run_rake_task('gitlab:gitaly:clone', clone_path) }.to raise_error(/Please specify the directory where you want to install gitaly and the path for the default storage/)
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
      it 'calls checkout_or_clone_version with the right arguments' do
        expect(main_object)
          .to receive(:checkout_or_clone_version).with(version: version, repo: repo, target_dir: clone_path, clone_opts: %w[--depth 1])

        subject
      end
    end
  end

  describe 'install' do
    subject { run_rake_task('gitlab:gitaly:install', clone_path, storage_path) }

    describe 'gmake/make' do
      before do
        stub_env('CI', false)
        FileUtils.mkdir_p(clone_path)
        expect(Dir).to receive(:chdir).with(clone_path).and_call_original
        stub_rails_env('development')
      end

      context 'gmake is available' do
        it 'calls gmake in the gitaly directory' do
          expect(Gitlab::Popen).to receive(:popen)
            .with(%w[which gmake])
            .and_return(['/usr/bin/gmake', 0])
          expect(Gitlab::Popen).to receive(:popen)
            .with(%w[gmake clean all])
            .and_return(['ok', 0])

          subject
        end

        context 'when gmake fails' do
          it 'aborts process' do
            expect(Gitlab::Popen).to receive(:popen)
              .with(%w[which gmake])
              .and_return(['/usr/bin/gmake', 0])
            expect(Gitlab::Popen).to receive(:popen)
              .with(%w[gmake clean all])
              .and_return(['output', 1])

            expect { subject }.to raise_error(/Gitaly failed to compile: output/)
          end
        end
      end

      context 'gmake is not available' do
        before do
          expect(Gitlab::Popen).to receive(:popen)
            .with(%w[which gmake])
            .and_return(['', 42])
        end

        it 'calls make in the gitaly directory' do
          expect(Gitlab::Popen).to receive(:popen)
            .with(%w[make clean all])
            .and_return(['output', 0])

          subject
        end
      end
    end
  end

  describe 'update_removed_storage_projects' do
    let(:removed_storage_name) { 'removed_storage' }
    let(:target_storage_name) { 'target_storage' }
    let(:message) { "1 projects from storage #{removed_storage_name} to #{target_storage_name} in the Rails database." }
    let_it_be(:project) { create(:project) } # rubocop: disable RSpec/AvoidTestProf -- This is not a migration spec

    before do
      project.update_column(:repository_storage, removed_storage_name)
    end

    subject { run_rake_task('gitlab:gitaly:update_removed_storage_projects', removed_storage_name, target_storage_name) }

    context 'no removed storage name given' do
      it 'aborts and display a help message' do
        # avoid writing task output to spec progresdoc/development/gotchas.mds
        allow($stderr).to receive :write
        expect { run_rake_task('gitlab:gitaly:update_removed_storage_projects') }.to raise_error(/Please specify the names of the removed storage and the storage to move projects to/)
      end
    end

    context 'no target storage name given' do
      it 'aborts and display a help message' do
        allow($stderr).to receive :write
        expect { run_rake_task('gitlab:gitaly:update_removed_storage_projects', removed_storage_name) }.to raise_error(/Please specify the names of the removed storage and the storage to move projects to/)
      end
    end

    context 'dry run' do
      it 'displays the number of projects and does not update them' do
        allow($stdout).to receive :write
        expect { subject }.to output(match(/^DRY RUN: would have updated #{message}/)).to_stdout

        project.reload

        expect(project.repository_storage).to eq(removed_storage_name)
      end
    end

    it 'updates the projects storage' do
      stub_env('APPLY', '1')

      allow($stdout).to receive :write
      expect { subject }.to output(match(/^Updating #{message}$/)).to_stdout

      project.reload

      expect(project.repository_storage).to eq(target_storage_name)
    end
  end
end

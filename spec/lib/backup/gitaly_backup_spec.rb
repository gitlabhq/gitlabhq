# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::GitalyBackup, feature_category: :backup_restore do
  let(:max_parallelism) { nil }
  let(:storage_parallelism) { nil }
  let(:destination) { File.join(Gitlab.config.backup.path, 'repositories') }
  let(:backup_id) { '20220101' }
  let(:server_side) { false }

  let(:progress) do
    Tempfile.new('progress').tap(&:unlink)
  end

  let(:expected_env) do
    {
      'SSL_CERT_FILE' => Gitlab::X509::Certificate.default_cert_file,
      'SSL_CERT_DIR' => Gitlab::X509::Certificate.default_cert_dir,
      'GITALY_SERVERS' => anything
    }.merge(ENV)
  end

  after do
    progress.close
  end

  subject do
    described_class.new(
      progress,
      max_parallelism: max_parallelism,
      storage_parallelism: storage_parallelism,
      server_side: server_side
    )
  end

  context 'unknown' do
    it 'fails to start unknown' do
      expect { subject.start(:unknown, destination, backup_id: backup_id) }.to raise_error(::Backup::Error, 'unknown backup type: unknown')
    end
  end

  context 'create' do
    RSpec.shared_examples 'creates a repository backup' do
      it 'creates repository bundles', :aggregate_failures do
        # Add data to the wiki, and snippets, so they will be included in the dump.
        # Design repositories already have data through the factory :project_with_design
        create(:wiki_page, container: project)
        project_snippet = create(:project_snippet, :repository, project: project)
        personal_snippet = create(:personal_snippet, :repository, author: project.first_owner)

        expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-path', anything, '-layout', 'manifest', '-id', backup_id).and_call_original

        subject.start(:create, destination, backup_id: backup_id)
        subject.enqueue(project, Gitlab::GlRepository::PROJECT)
        subject.enqueue(project, Gitlab::GlRepository::WIKI)
        subject.enqueue(project.design_management_repository, Gitlab::GlRepository::DESIGN)
        subject.enqueue(personal_snippet, Gitlab::GlRepository::SNIPPET)
        subject.enqueue(project_snippet, Gitlab::GlRepository::SNIPPET)
        subject.finish!

        expect(File).to exist(File.join(destination, 'manifests/default', project.repository.relative_path, "#{backup_id}.toml"))
        expect(File).to exist(File.join(destination, 'manifests/default', project.repository.relative_path, "+latest.toml"))
      end

      it 'erases any existing repository backups' do
        existing_file = File.join(destination, 'some_existing_file')
        File.write(existing_file, "Some existing file.\n")

        subject.start(:create, destination, backup_id: backup_id)
        subject.finish!

        expect(File).not_to exist(existing_file)
      end

      context 'parallel option set' do
        let(:max_parallelism) { 3 }

        it 'passes parallel option through' do
          expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-path', anything, '-layout', 'manifest', '-parallel', '3', '-id', backup_id).and_call_original

          subject.start(:create, destination, backup_id: backup_id)
          subject.finish!
        end
      end

      context 'parallel_storage option set' do
        let(:storage_parallelism) { 3 }

        it 'passes parallel option through' do
          expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-path', anything, '-layout', 'manifest', '-parallel-storage', '3', '-id', backup_id).and_call_original

          subject.start(:create, destination, backup_id: backup_id)
          subject.finish!
        end
      end

      context 'server-side option set' do
        let(:server_side) { true }

        it 'passes option through' do
          expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-server-side', '-id', backup_id).and_call_original

          subject.start(:create, destination, backup_id: backup_id)
          subject.finish!
        end
      end

      it 'raises when the exit code not zero' do
        expect(subject).to receive(:bin_path).and_return(Gitlab::Utils.which('false'))

        subject.start(:create, destination, backup_id: backup_id)
        expect { subject.finish! }.to raise_error(::Backup::Error, 'gitaly-backup exit status 1')
      end

      it 'raises when gitaly_backup_path is not set' do
        stub_backup_setting(gitaly_backup_path: nil)

        expect { subject.start(:create, destination, backup_id: backup_id) }.to raise_error(::Backup::Error, 'gitaly-backup binary not found and gitaly_backup_path is not configured')
      end
    end

    context 'hashed storage' do
      let_it_be(:project) { create(:project_with_design, :repository) }

      it_behaves_like 'creates a repository backup'
    end

    context 'legacy storage' do
      let_it_be(:project) { create(:project_with_design, :repository, :legacy_storage) }

      it_behaves_like 'creates a repository backup'
    end

    context 'custom SSL envs set' do
      let(:ssl_env) do
        {
          'SSL_CERT_FILE' => '/some/cert/file',
          'SSL_CERT_DIR' => '/some/cert'
        }
      end

      let(:expected_env) do
        ssl_env.merge(
          'GITALY_SERVERS' => anything
        )
      end

      it 'passes through SSL envs' do
        expect(subject).to receive(:current_env).and_return(ssl_env)
        expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-path', anything, '-layout', 'manifest', '-id', backup_id).and_call_original

        subject.start(:create, destination, backup_id: backup_id)
        subject.finish!
      end
    end
  end

  context 'restore' do
    let_it_be(:project) { create(:project_with_design, :repository) }
    let_it_be(:personal_snippet) { create(:personal_snippet, author: project.first_owner) }
    let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.first_owner) }

    def create_repo_backup(backup_name, repo)
      repo_backup_root = File.join(Gitlab.config.backup.path, 'repositories')

      FileUtils.mkdir_p(File.join(repo_backup_root, 'manifests', repo.storage, repo.relative_path))
      FileUtils.mkdir_p(File.join(repo_backup_root, repo.relative_path))

      %w[.bundle .refs].each do |filetype|
        FileUtils.cp(
          Rails.root.join('spec/fixtures/lib/backup', backup_name + filetype),
          File.join(repo_backup_root, repo.relative_path + filetype)
        )
      end

      manifest = <<-TOML
        object_format = 'sha1'
        head_references = 'heads/refs/master'

        [[steps]]
        bundle_path = '#{repo.relative_path}.bundle'
        ref_path = '#{repo.relative_path}.refs'
        custom_hooks_path = '#{repo.relative_path}.custom_hooks.tar'
      TOML

      File.write(File.join(repo_backup_root, 'manifests', repo.storage, repo.relative_path, "#{backup_id}.toml"), manifest)
    end

    it 'restores from repository bundles', :aggregate_failures do
      create_repo_backup('project_repo', project.repository.raw)
      create_repo_backup('wiki_repo', project.wiki.repository)
      create_repo_backup('design_repo', project.design_repository)
      create_repo_backup('personal_snippet_repo', personal_snippet.repository)
      create_repo_backup('project_snippet_repo', project_snippet.repository)

      expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything, '-layout', 'manifest', '-id', backup_id).and_call_original

      subject.start(:restore, destination, backup_id: backup_id)
      subject.enqueue(project, Gitlab::GlRepository::PROJECT)
      subject.enqueue(project, Gitlab::GlRepository::WIKI)
      subject.enqueue(project.design_management_repository, Gitlab::GlRepository::DESIGN)
      subject.enqueue(personal_snippet, Gitlab::GlRepository::SNIPPET)
      subject.enqueue(project_snippet, Gitlab::GlRepository::SNIPPET)
      subject.finish!

      collect_commit_shas = ->(repo) { repo.commits('master', limit: 10).map(&:sha) }

      expect(collect_commit_shas.call(project.repository)).to match_array(['393a7d860a5a4c3cc736d7eb00604e3472bb95ec'])
      expect(collect_commit_shas.call(project.wiki.repository)).to match_array(['c74b9948d0088d703ee1fafeddd9ed9add2901ea'])
      expect(collect_commit_shas.call(project.design_repository)).to match_array(['c3cd4d7bd73a51a0f22045c3a4c871c435dc959d'])
      expect(collect_commit_shas.call(personal_snippet.repository)).to match_array(['3b3c067a3bc1d1b695b51e2be30c0f8cf698a06e'])
      expect(collect_commit_shas.call(project_snippet.repository)).to match_array(['6e44ba56a4748be361a841e759c20e421a1651a1'])
    end

    it 'clears specified storages when remove_all_repositories is set' do
      expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything, '-layout', 'manifest', '-remove-all-repositories', 'default', '-id', backup_id).and_call_original

      create_repo_backup('project_repo', project.repository.raw)
      subject.start(:restore, destination, backup_id: backup_id, remove_all_repositories: %w[default])
      subject.enqueue(project, Gitlab::GlRepository::PROJECT)
      subject.finish!
    end

    context 'parallel option set' do
      let(:max_parallelism) { 3 }

      it 'passes parallel option through' do
        expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything, '-layout', 'manifest', '-parallel', '3', '-id', backup_id).and_call_original

        subject.start(:restore, destination, backup_id: backup_id)
        subject.finish!
      end
    end

    context 'parallel_storage option set' do
      let(:storage_parallelism) { 3 }

      it 'passes parallel option through' do
        expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything, '-layout', 'manifest', '-parallel-storage', '3', '-id', backup_id).and_call_original

        subject.start(:restore, destination, backup_id: backup_id)
        subject.finish!
      end
    end

    context 'server-side option set' do
      let(:server_side) { true }

      it 'passes option through' do
        expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-server-side', '-id', backup_id).and_call_original

        subject.start(:restore, destination, backup_id: backup_id)
        subject.finish!
      end

      context 'missing backup_id' do
        it 'wont set the option' do
          expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-server-side').and_call_original

          subject.start(:restore, destination)
          subject.finish!
        end
      end
    end

    context 'missing backup_id' do
      it 'wont set the option' do
        expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything, '-layout', 'manifest').and_call_original

        subject.start(:restore, destination)
        subject.finish!
      end
    end

    it 'raises when the exit code not zero' do
      expect(subject).to receive(:bin_path).and_return(Gitlab::Utils.which('false'))

      subject.start(:restore, destination, backup_id: backup_id)
      expect { subject.finish! }.to raise_error(::Backup::Error, 'gitaly-backup exit status 1')
    end

    it 'raises when gitaly_backup_path is not set' do
      stub_backup_setting(gitaly_backup_path: nil)

      expect { subject.start(:restore, destination, backup_id: backup_id) }.to raise_error(::Backup::Error, 'gitaly-backup binary not found and gitaly_backup_path is not configured')
    end
  end
end

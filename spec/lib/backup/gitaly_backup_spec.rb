# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::GitalyBackup do
  let(:max_parallelism) { nil }
  let(:storage_parallelism) { nil }
  let(:destination) { File.join(Gitlab.config.backup.path, 'repositories') }
  let(:backup_id) { '20220101' }

  let(:progress) do
    Tempfile.new('progress').tap do |progress|
      progress.unlink
    end
  end

  let(:expected_env) do
    {
      'SSL_CERT_FILE' => OpenSSL::X509::DEFAULT_CERT_FILE,
      'SSL_CERT_DIR'  => OpenSSL::X509::DEFAULT_CERT_DIR
    }.merge(ENV)
  end

  after do
    progress.close
  end

  subject { described_class.new(progress, max_parallelism: max_parallelism, storage_parallelism: storage_parallelism) }

  context 'unknown' do
    it 'fails to start unknown' do
      expect { subject.start(:unknown, destination, backup_id: backup_id) }.to raise_error(::Backup::Error, 'unknown backup type: unknown')
    end
  end

  context 'create' do
    RSpec.shared_examples 'creates a repository backup' do
      it 'creates repository bundles', :aggregate_failures do
        # Add data to the wiki, design repositories, and snippets, so they will be included in the dump.
        create(:wiki_page, container: project)
        create(:design, :with_file, issue: create(:issue, project: project))
        project_snippet = create(:project_snippet, :repository, project: project)
        personal_snippet = create(:personal_snippet, :repository, author: project.first_owner)

        expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-path', anything, '-layout', 'pointer', '-id', backup_id).and_call_original

        subject.start(:create, destination, backup_id: backup_id)
        subject.enqueue(project, Gitlab::GlRepository::PROJECT)
        subject.enqueue(project, Gitlab::GlRepository::WIKI)
        subject.enqueue(project, Gitlab::GlRepository::DESIGN)
        subject.enqueue(personal_snippet, Gitlab::GlRepository::SNIPPET)
        subject.enqueue(project_snippet, Gitlab::GlRepository::SNIPPET)
        subject.finish!

        expect(File).to exist(File.join(destination, project.disk_path, backup_id, '001.bundle'))
        expect(File).to exist(File.join(destination, project.disk_path + '.wiki', backup_id, '001.bundle'))
        expect(File).to exist(File.join(destination, project.disk_path + '.design', backup_id, '001.bundle'))
        expect(File).to exist(File.join(destination, personal_snippet.disk_path, backup_id, '001.bundle'))
        expect(File).to exist(File.join(destination, project_snippet.disk_path, backup_id, '001.bundle'))
      end

      it 'erases any existing repository backups' do
        existing_file = File.join(destination, 'some_existing_file')
        IO.write(existing_file, "Some existing file.\n")

        subject.start(:create, destination, backup_id: backup_id)
        subject.finish!

        expect(File).not_to exist(existing_file)
      end

      context 'parallel option set' do
        let(:max_parallelism) { 3 }

        it 'passes parallel option through' do
          expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-path', anything, '-parallel', '3', '-layout', 'pointer', '-id', backup_id).and_call_original

          subject.start(:create, destination, backup_id: backup_id)
          subject.finish!
        end
      end

      context 'parallel_storage option set' do
        let(:storage_parallelism) { 3 }

        it 'passes parallel option through' do
          expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-path', anything, '-parallel-storage', '3', '-layout', 'pointer', '-id', backup_id).and_call_original

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

      context 'feature flag incremental_repository_backup disabled' do
        before do
          stub_feature_flags(incremental_repository_backup: false)
        end

        it 'creates repository bundles', :aggregate_failures do
          # Add data to the wiki, design repositories, and snippets, so they will be included in the dump.
          create(:wiki_page, container: project)
          create(:design, :with_file, issue: create(:issue, project: project))
          project_snippet = create(:project_snippet, :repository, project: project)
          personal_snippet = create(:personal_snippet, :repository, author: project.first_owner)

          expect(Open3).to receive(:popen2).with(expected_env, anything, 'create', '-path', anything).and_call_original

          subject.start(:create, destination, backup_id: backup_id)
          subject.enqueue(project, Gitlab::GlRepository::PROJECT)
          subject.enqueue(project, Gitlab::GlRepository::WIKI)
          subject.enqueue(project, Gitlab::GlRepository::DESIGN)
          subject.enqueue(personal_snippet, Gitlab::GlRepository::SNIPPET)
          subject.enqueue(project_snippet, Gitlab::GlRepository::SNIPPET)
          subject.finish!

          expect(File).to exist(File.join(destination, project.disk_path + '.bundle'))
          expect(File).to exist(File.join(destination, project.disk_path + '.wiki.bundle'))
          expect(File).to exist(File.join(destination, project.disk_path + '.design.bundle'))
          expect(File).to exist(File.join(destination, personal_snippet.disk_path + '.bundle'))
          expect(File).to exist(File.join(destination, project_snippet.disk_path + '.bundle'))
        end
      end
    end

    context 'hashed storage' do
      let_it_be(:project) { create(:project, :repository) }

      it_behaves_like 'creates a repository backup'
    end

    context 'legacy storage' do
      let_it_be(:project) { create(:project, :repository, :legacy_storage) }

      it_behaves_like 'creates a repository backup'
    end

    context 'custom SSL envs set' do
      let(:ssl_env) do
        {
          'SSL_CERT_FILE' => '/some/cert/file',
          'SSL_CERT_DIR'  => '/some/cert'
        }
      end

      before do
        stub_const('ENV', ssl_env)
      end

      it 'passes through SSL envs' do
        expect(Open3).to receive(:popen2).with(ssl_env, anything, 'create', '-path', anything, '-layout', 'pointer', '-id', backup_id).and_call_original

        subject.start(:create, destination, backup_id: backup_id)
        subject.finish!
      end
    end
  end

  context 'restore' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:personal_snippet) { create(:personal_snippet, author: project.first_owner) }
    let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.first_owner) }

    def copy_bundle_to_backup_path(bundle_name, destination)
      FileUtils.mkdir_p(File.join(Gitlab.config.backup.path, 'repositories', File.dirname(destination)))
      FileUtils.cp(Rails.root.join('spec/fixtures/lib/backup', bundle_name), File.join(Gitlab.config.backup.path, 'repositories', destination))
    end

    it 'restores from repository bundles', :aggregate_failures do
      copy_bundle_to_backup_path('project_repo.bundle', project.disk_path + '.bundle')
      copy_bundle_to_backup_path('wiki_repo.bundle', project.disk_path + '.wiki.bundle')
      copy_bundle_to_backup_path('design_repo.bundle', project.disk_path + '.design.bundle')
      copy_bundle_to_backup_path('personal_snippet_repo.bundle', personal_snippet.disk_path + '.bundle')
      copy_bundle_to_backup_path('project_snippet_repo.bundle', project_snippet.disk_path + '.bundle')

      expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything, '-layout', 'pointer').and_call_original

      subject.start(:restore, destination, backup_id: backup_id)
      subject.enqueue(project, Gitlab::GlRepository::PROJECT)
      subject.enqueue(project, Gitlab::GlRepository::WIKI)
      subject.enqueue(project, Gitlab::GlRepository::DESIGN)
      subject.enqueue(personal_snippet, Gitlab::GlRepository::SNIPPET)
      subject.enqueue(project_snippet, Gitlab::GlRepository::SNIPPET)
      subject.finish!

      collect_commit_shas = -> (repo) { repo.commits('master', limit: 10).map(&:sha) }

      expect(collect_commit_shas.call(project.repository)).to match_array(['393a7d860a5a4c3cc736d7eb00604e3472bb95ec'])
      expect(collect_commit_shas.call(project.wiki.repository)).to match_array(['c74b9948d0088d703ee1fafeddd9ed9add2901ea'])
      expect(collect_commit_shas.call(project.design_repository)).to match_array(['c3cd4d7bd73a51a0f22045c3a4c871c435dc959d'])
      expect(collect_commit_shas.call(personal_snippet.repository)).to match_array(['3b3c067a3bc1d1b695b51e2be30c0f8cf698a06e'])
      expect(collect_commit_shas.call(project_snippet.repository)).to match_array(['6e44ba56a4748be361a841e759c20e421a1651a1'])
    end

    context 'parallel option set' do
      let(:max_parallelism) { 3 }

      it 'passes parallel option through' do
        expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything, '-parallel', '3', '-layout', 'pointer').and_call_original

        subject.start(:restore, destination, backup_id: backup_id)
        subject.finish!
      end
    end

    context 'parallel_storage option set' do
      let(:storage_parallelism) { 3 }

      it 'passes parallel option through' do
        expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything, '-parallel-storage', '3', '-layout', 'pointer').and_call_original

        subject.start(:restore, destination, backup_id: backup_id)
        subject.finish!
      end
    end

    context 'feature flag incremental_repository_backup disabled' do
      before do
        stub_feature_flags(incremental_repository_backup: false)
      end

      it 'restores from repository bundles', :aggregate_failures do
        copy_bundle_to_backup_path('project_repo.bundle', project.disk_path + '.bundle')
        copy_bundle_to_backup_path('wiki_repo.bundle', project.disk_path + '.wiki.bundle')
        copy_bundle_to_backup_path('design_repo.bundle', project.disk_path + '.design.bundle')
        copy_bundle_to_backup_path('personal_snippet_repo.bundle', personal_snippet.disk_path + '.bundle')
        copy_bundle_to_backup_path('project_snippet_repo.bundle', project_snippet.disk_path + '.bundle')

        expect(Open3).to receive(:popen2).with(expected_env, anything, 'restore', '-path', anything).and_call_original

        subject.start(:restore, destination, backup_id: backup_id)
        subject.enqueue(project, Gitlab::GlRepository::PROJECT)
        subject.enqueue(project, Gitlab::GlRepository::WIKI)
        subject.enqueue(project, Gitlab::GlRepository::DESIGN)
        subject.enqueue(personal_snippet, Gitlab::GlRepository::SNIPPET)
        subject.enqueue(project_snippet, Gitlab::GlRepository::SNIPPET)
        subject.finish!

        collect_commit_shas = -> (repo) { repo.commits('master', limit: 10).map(&:sha) }

        expect(collect_commit_shas.call(project.repository)).to match_array(['393a7d860a5a4c3cc736d7eb00604e3472bb95ec'])
        expect(collect_commit_shas.call(project.wiki.repository)).to match_array(['c74b9948d0088d703ee1fafeddd9ed9add2901ea'])
        expect(collect_commit_shas.call(project.design_repository)).to match_array(['c3cd4d7bd73a51a0f22045c3a4c871c435dc959d'])
        expect(collect_commit_shas.call(personal_snippet.repository)).to match_array(['3b3c067a3bc1d1b695b51e2be30c0f8cf698a06e'])
        expect(collect_commit_shas.call(project_snippet.repository)).to match_array(['6e44ba56a4748be361a841e759c20e421a1651a1'])
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

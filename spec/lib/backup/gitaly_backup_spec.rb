# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::GitalyBackup do
  let(:parallel) { nil }
  let(:progress) do
    Tempfile.new('progress').tap do |progress|
      progress.unlink
    end
  end

  after do
    progress.close
  end

  subject { described_class.new(progress, parallel: parallel) }

  context 'unknown' do
    it 'fails to start unknown' do
      expect { subject.start(:unknown) }.to raise_error(::Backup::Error, 'unknown backup type: unknown')
    end
  end

  context 'create' do
    RSpec.shared_examples 'creates a repository backup' do
      it 'creates repository bundles', :aggregate_failures do
        # Add data to the wiki, design repositories, and snippets, so they will be included in the dump.
        create(:wiki_page, container: project)
        create(:design, :with_file, issue: create(:issue, project: project))
        project_snippet = create(:project_snippet, :repository, project: project)
        personal_snippet = create(:personal_snippet, :repository, author: project.owner)

        expect(Process).to receive(:spawn).with(anything, 'create', '-path', anything, { in: anything, out: progress }).and_call_original

        subject.start(:create)
        subject.enqueue(project, Gitlab::GlRepository::PROJECT)
        subject.enqueue(project, Gitlab::GlRepository::WIKI)
        subject.enqueue(project, Gitlab::GlRepository::DESIGN)
        subject.enqueue(personal_snippet, Gitlab::GlRepository::SNIPPET)
        subject.enqueue(project_snippet, Gitlab::GlRepository::SNIPPET)
        subject.wait

        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project.disk_path + '.bundle'))
        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project.disk_path + '.wiki.bundle'))
        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project.disk_path + '.design.bundle'))
        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', personal_snippet.disk_path + '.bundle'))
        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project_snippet.disk_path + '.bundle'))
      end

      context 'parallel option set' do
        let(:parallel) { 3 }

        it 'passes parallel option through' do
          expect(Process).to receive(:spawn).with(anything, 'create', '-path', anything, '-parallel', '3', { in: anything, out: progress }).and_call_original

          subject.start(:create)
          subject.wait
        end
      end

      it 'raises when the exit code not zero' do
        expect(subject).to receive(:bin_path).and_return(Gitlab::Utils.which('false'))

        subject.start(:create)
        expect { subject.wait }.to raise_error(::Backup::Error, 'gitaly-backup exit status 1')
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
  end

  context 'restore' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:personal_snippet) { create(:personal_snippet, author: project.owner) }
    let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.owner) }

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

      expect(Process).to receive(:spawn).with(anything, 'restore', '-path', anything, { in: anything, out: progress }).and_call_original

      subject.start(:restore)
      subject.enqueue(project, Gitlab::GlRepository::PROJECT)
      subject.enqueue(project, Gitlab::GlRepository::WIKI)
      subject.enqueue(project, Gitlab::GlRepository::DESIGN)
      subject.enqueue(personal_snippet, Gitlab::GlRepository::SNIPPET)
      subject.enqueue(project_snippet, Gitlab::GlRepository::SNIPPET)
      subject.wait

      collect_commit_shas = -> (repo) { repo.commits('master', limit: 10).map(&:sha) }

      expect(collect_commit_shas.call(project.repository)).to eq(['393a7d860a5a4c3cc736d7eb00604e3472bb95ec'])
      expect(collect_commit_shas.call(project.wiki.repository)).to eq(['c74b9948d0088d703ee1fafeddd9ed9add2901ea'])
      expect(collect_commit_shas.call(project.design_repository)).to eq(['c3cd4d7bd73a51a0f22045c3a4c871c435dc959d'])
      expect(collect_commit_shas.call(personal_snippet.repository)).to eq(['3b3c067a3bc1d1b695b51e2be30c0f8cf698a06e'])
      expect(collect_commit_shas.call(project_snippet.repository)).to eq(['6e44ba56a4748be361a841e759c20e421a1651a1'])
    end

    context 'parallel option set' do
      let(:parallel) { 3 }

      it 'does not pass parallel option through' do
        expect(Process).to receive(:spawn).with(anything, 'restore', '-path', anything, { in: anything, out: progress }).and_call_original

        subject.start(:restore)
        subject.wait
      end
    end

    it 'raises when the exit code not zero' do
      expect(subject).to receive(:bin_path).and_return(Gitlab::Utils.which('false'))

      subject.start(:restore)
      expect { subject.wait }.to raise_error(::Backup::Error, 'gitaly-backup exit status 1')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::ChangelogService, feature_category: :source_code_management do
  describe '#execute' do
    let!(:project) { create(:project, :empty_repo) }
    let!(:creator) { project.creator }
    let!(:author1) { create(:user) }
    let!(:author2) { create(:user) }
    let!(:mr1) { create(:merge_request, :merged, target_project: project) }
    let!(:mr2) { create(:merge_request, :merged, target_project: project) }

    # The range of commits ignores the first commit, but includes the last
    # commit. To ensure both the commits below are included, we must create an
    # extra commit.
    #
    # In the real world, the start commit of the range will be the last commit
    # of the previous release, so ignoring that is expected and desired.
    let!(:sha1) do
      create_commit(
        project,
        creator,
        commit_message: 'Initial commit',
        actions: [{ action: 'create', content: 'test', file_path: 'README.md' }]
      )
    end

    let!(:sha2) do
      project.add_maintainer(author1)

      create_commit(
        project,
        author1,
        commit_message: "Title 1\n\nChangelog: feature",
        actions: [{ action: 'create', content: 'foo', file_path: 'a.txt' }]
      )
    end

    let!(:sha3) do
      project.add_maintainer(author2)

      create_commit(
        project,
        author2,
        commit_message: "Title 2\n\nChangelog: feature",
        actions: [{ action: 'create', content: 'bar', file_path: 'b.txt' }]
      )
    end

    let!(:sha4) do
      create_commit(
        project,
        author2,
        commit_message: "Title 3\n\nChangelog: feature",
        actions: [{ action: 'create', content: 'bar', file_path: 'c.txt' }]
      )
    end

    let!(:commit1) { project.commit(sha2) }
    let!(:commit2) { project.commit(sha3) }
    let!(:commit3) { project.commit(sha4) }

    let(:commit_to_changelog) { true }

    it 'generates and commits a changelog section' do
      allow(MergeRequestDiffCommit)
        .to receive(:oldest_merge_request_id_per_commit)
        .with(project.id, [commit2.id, commit1.id])
        .and_return(
          [
            { sha: sha2, merge_request_id: mr1.id },
            { sha: sha3, merge_request_id: mr2.id }
          ])

      service = described_class
        .new(project, creator, version: '1.0.0', from: sha1, to: sha3)

      recorder = ActiveRecord::QueryRecorder.new { service.execute(commit_to_changelog: commit_to_changelog) }
      changelog = project.repository.blob_at('master', 'CHANGELOG.md')&.data

      expect(recorder.count).to eq(15)
      expect(changelog).to include('Title 1', 'Title 2')
    end

    it "ignores a commit when it's both added and reverted in the same range" do
      create_commit(
        project,
        author2,
        commit_message: "Title 4\n\nThis reverts commit #{sha4}",
        actions: [{ action: 'create', content: 'bar', file_path: 'd.txt' }]
      )

      described_class
        .new(project, creator, version: '1.0.0', from: sha1)
        .execute(commit_to_changelog: commit_to_changelog)

      changelog = project.repository.blob_at('master', 'CHANGELOG.md')&.data

      expect(changelog).to include('Title 1', 'Title 2')
      expect(changelog).not_to include('Title 3', 'Title 4')
    end

    it 'includes a revert commit when it has a trailer' do
      create_commit(
        project,
        author2,
        commit_message: "Title 4\n\nThis reverts commit #{sha4}\n\nChangelog: added",
        actions: [{ action: 'create', content: 'bar', file_path: 'd.txt' }]
      )

      described_class
        .new(project, creator, version: '1.0.0', from: sha1)
        .execute(commit_to_changelog: commit_to_changelog)

      changelog = project.repository.blob_at('master', 'CHANGELOG.md')&.data

      expect(changelog).to include('Title 1', 'Title 2', 'Title 4')
      expect(changelog).not_to include('Title 3')
    end

    it 'uses the target branch when "to" is unspecified' do
      described_class
        .new(project, creator, version: '1.0.0', from: sha1)
        .execute(commit_to_changelog: commit_to_changelog)

      changelog = project.repository.blob_at('master', 'CHANGELOG.md')&.data

      expect(changelog).to include('Title 1', 'Title 2', 'Title 3')
    end

    describe 'with commit_to_changelog: false' do
      let(:commit_to_changelog) { false }

      it 'generates changelog section' do
        allow(MergeRequestDiffCommit)
          .to receive(:oldest_merge_request_id_per_commit)
          .with(project.id, [commit2.id, commit1.id])
          .and_return(
            [
              { sha: sha2, merge_request_id: mr1.id },
              { sha: sha3, merge_request_id: mr2.id }
            ])

        service = described_class
          .new(project, creator, version: '1.0.0', from: sha1, to: sha3)

        changelog = service.execute(commit_to_changelog: commit_to_changelog)

        expect(changelog).to include('Title 1', 'Title 2')
      end
    end

    it 'avoids N+1 queries', :request_store do
      RequestStore.clear!

      request = ->(to) do
        described_class
          .new(project, creator, version: '1.0.0', from: sha1, to: to)
          .execute(commit_to_changelog: false)
      end

      control = ActiveRecord::QueryRecorder.new { request.call(sha2) }

      RequestStore.clear!

      expect { request.call(sha3) }.not_to exceed_query_limit(control)
    end

    context 'when one of commits does not exist' do
      let(:service) { described_class.new(project, creator, version: '1.0.0', from: 'master', to: '54321') }

      it 'raises an exception' do
        expect { service.execute(commit_to_changelog: false) }.to raise_error(Gitlab::Changelog::Error)
      end
    end

    context 'when commit range exceeds the limit' do
      let(:service) { described_class.new(project, creator, version: '1.0.0', from: sha1) }

      before do
        stub_const("#{described_class.name}::COMMITS_LIMIT", 2)
      end

      it 'raises an exception' do
        expect { service.execute(commit_to_changelog: false) }.to raise_error(Gitlab::Changelog::Error)
      end
    end

    context 'with specified changelog config file path' do
      it 'return specified changelog content' do
        config = Gitlab::Changelog::Config.from_hash(project, { 'template' => 'specified_changelog_content' }, creator)

        allow(Gitlab::Changelog::Config)
          .to receive(:from_git)
          .with(project, creator, 'specified_changelog_config.yml', 'HEAD')
          .and_return(config)

        described_class
          .new(project, creator, version: '1.0.0', from: sha1, config_file: 'specified_changelog_config.yml')
          .execute(commit_to_changelog: commit_to_changelog)

        changelog = project.repository.blob_at('master', 'CHANGELOG.md')&.data

        expect(changelog).to include('specified_changelog_content')
      end
    end

    context 'when changelog config file is located in a specific branch' do
      subject { described_class.new(project, creator, **service_params).execute(commit_to_changelog: false) }

      let(:service_params) { { version: '1.0.0', from: sha1, config_file: changelog_file_path } }
      let(:changelog_content) { YAML.dump('template' => 'custom changelog') }
      let(:changelog_file_path) { 'custom_changelog.yml' }
      let(:custom_branch) { 'foo' }

      before do
        create_commit(
          project,
          creator,
          commit_message: 'Custom changelog file',
          branch_name: custom_branch,
          actions: [{ action: 'create', content: changelog_content, file_path: changelog_file_path }]
        )
      end

      context 'without config_file_ref' do
        it 'returns a default changelog template' do
          is_expected.not_to include 'custom changelog'
        end
      end

      context 'with config_file_ref' do
        let(:service_params) { super().merge(config_file_ref: custom_branch) }

        it 'applies the correct changelog config' do
          is_expected.to include 'custom changelog'
        end
      end
    end
  end

  describe '#start_of_commit_range' do
    let(:project) { build_stubbed(:project) }
    let(:user) { build_stubbed(:user) }
    let(:config) { Gitlab::Changelog::Config.new(project) }

    context 'when the "from" argument is specified' do
      it 'returns the value of the argument' do
        service = described_class
          .new(project, user, version: '1.0.0', from: 'foo', to: 'bar')

        expect(service.start_of_commit_range(config)).to eq('foo')
      end
    end

    context 'when the "from" argument is unspecified' do
      it 'returns the tag commit of the previous version' do
        service = described_class
          .new(project, user, version: '1.0.0', to: 'bar')

        finder_spy = instance_spy(::Repositories::ChangelogTagFinder)
        tag = double(:tag, target_commit: double(:commit, id: '123'))

        allow(::Repositories::ChangelogTagFinder)
          .to receive(:new)
          .with(project, regex: an_instance_of(String))
          .and_return(finder_spy)

        allow(finder_spy)
          .to receive(:execute)
          .with('1.0.0')
          .and_return(tag)

        expect(service.start_of_commit_range(config)).to eq('123')
      end

      it 'raises an error when no tag is found' do
        service = described_class
          .new(project, user, version: '1.0.0', to: 'bar')

        finder_spy = instance_spy(::Repositories::ChangelogTagFinder)

        allow(::Repositories::ChangelogTagFinder)
          .to receive(:new)
          .with(project, regex: an_instance_of(String))
          .and_return(finder_spy)

        allow(finder_spy)
          .to receive(:execute)
          .with('1.0.0')
          .and_return(nil)

        expect { service.start_of_commit_range(config) }
          .to raise_error(Gitlab::Changelog::Error)
      end
    end
  end

  def create_commit(project, user, params)
    RequestStore.clear!

    params = { start_branch: 'master', branch_name: 'master' }.merge(params)
    Files::MultiService.new(project, user, params).execute.fetch(:result)
  end
end

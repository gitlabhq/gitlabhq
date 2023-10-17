# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::ObjectBuilder do
  let!(:group) { create(:group, :private) }
  let!(:subgroup) { create(:group, :private, parent: group) }
  let!(:project) do
    create(
      :project,
      :repository,
      :builds_disabled,
      :issues_disabled,
      name: 'project',
      path: 'project',
      group: subgroup
    )
  end

  let(:lru_cache) { subject.send(:lru_cache) }
  let(:cache_key) { subject.send(:cache_key) }

  context 'request store is not active' do
    subject do
      described_class.new(Label, 'title' => 'group label', 'project' => project, 'group' => project.group)
    end

    it 'ignore cache initialize' do
      expect(lru_cache).to be_nil
      expect(cache_key).to be_nil
    end
  end

  context 'request store is active', :request_store do
    subject do
      described_class.new(Label, 'title' => 'group label', 'project' => project, 'group' => project.group)
    end

    it 'initialize cache in memory' do
      expect(lru_cache).not_to be_nil
      expect(cache_key).not_to be_nil
    end

    it 'cache object when first time find the object' do
      group_label = create(:group_label, name: 'group label', group: project.group)

      expect(subject).to receive(:find_object).and_call_original
      expect { subject.find }
        .to change { lru_cache[cache_key] }
        .from(nil).to(group_label)

      expect(subject.find).to eq(group_label)
    end

    it 'read from cache when object has been cached' do
      group_label = create(:group_label, name: 'group label', group: project.group)

      subject.find

      expect(subject).not_to receive(:find_object)
      expect { subject.find }.not_to change { lru_cache[cache_key] }

      expect(subject.find).to eq(group_label)
    end
  end

  context 'labels' do
    it 'finds the existing group label' do
      group_label = create(:group_label, name: 'group label', group: project.group)

      expect(described_class.build(
        Label,
        'title' => 'group label',
        'project' => project,
        'group' => project.group
      )).to eq(group_label)
    end

    it 'finds the existing group label in root ancestor' do
      group_label = create(:group_label, name: 'group label', group: group)

      expect(described_class.build(
        Label,
        'title' => 'group label',
        'project' => project,
        'group' => group
      )).to eq(group_label)
    end

    it 'creates a new project label' do
      label = described_class.build(
        Label,
        'title' => 'group label',
        'project' => project,
        'group' => project.group,
        'group_id' => project.group.id
      )

      expect(label.persisted?).to be true
      expect(label).to be_an_instance_of(ProjectLabel)
      expect(label.group_id).to be_nil
    end
  end

  context 'milestones' do
    it 'finds the existing group milestone' do
      milestone = create(:milestone, name: 'group milestone', group: project.group)

      expect(described_class.build(
        Milestone,
        'title' => 'group milestone',
        'project' => project,
        'group' => project.group
      )).to eq(milestone)
    end

    it 'finds the existing group milestone in root ancestor' do
      milestone = create(:milestone, name: 'group milestone', group: group)

      expect(described_class.build(
        Milestone,
        'title' => 'group milestone',
        'project' => project,
        'group' => group
      )).to eq(milestone)
    end

    it 'creates a new milestone' do
      milestone = described_class.build(
        Milestone,
        'title' => 'group milestone',
        'project' => project,
        'group' => project.group
      )

      expect(milestone.persisted?).to be true
    end

    context 'with clashing iid' do
      it 'creates milestone and claims iid for the new milestone' do
        clashing_iid = 1
        create(:milestone, iid: clashing_iid, project: project)

        milestone = described_class.build(
          Milestone,
          'iid' => clashing_iid,
          'title' => 'milestone',
          'project' => project,
          'group' => nil,
          'group_id' => nil
        )

        expect(milestone.persisted?).to be true
        expect(Milestone.count).to eq(2)
        expect(milestone.iid).to eq(clashing_iid)
      end
    end
  end

  context 'work item types', :request_store, feature_category: :team_planning do
    it 'returns the correct type by base type' do
      task_type = described_class.new(WorkItems::Type, { 'base_type' => 'task' }).find
      incident_type = described_class.new(WorkItems::Type, { 'base_type' => 'incident' }).find
      default_type = described_class.new(WorkItems::Type, { 'base_type' => 'bad_input' }).find

      expect(task_type).to eq(WorkItems::Type.default_by_type(:task))
      expect(incident_type).to eq(WorkItems::Type.default_by_type(:incident))
      expect(default_type).to eq(WorkItems::Type.default_by_type(:issue))
    end

    it 'caches the results' do
      builder = described_class.new(WorkItems::Type, { 'base_type' => 'task' })

      # Make sure finder works
      expect(builder.find).to be_a(WorkItems::Type)

      query_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        builder.find
      end.count

      expect(query_count).to be_zero
    end
  end

  context 'merge_request' do
    it 'finds the existing merge_request' do
      merge_request = create(
        :merge_request,
        title: 'MergeRequest',
        iid: 7,
        target_project: project,
        source_project: project
      )

      expect(described_class.build(
        MergeRequest,
        'title' => 'MergeRequest',
        'source_project_id' => project.id,
        'target_project_id' => project.id,
        'source_branch' => 'SourceBranch',
        'iid' => 7,
        'target_branch' => 'TargetBranch',
        'author_id' => project.creator.id
      )).to eq(merge_request)
    end

    it 'creates a new merge_request' do
      merge_request = described_class.build(
        MergeRequest,
        'title' => 'MergeRequest',
        'iid' => 8,
        'source_project_id' => project.id,
        'target_project_id' => project.id,
        'source_branch' => 'SourceBranch',
        'target_branch' => 'TargetBranch',
        'author_id' => project.creator.id
      )

      expect(merge_request.persisted?).to be true
    end
  end

  context 'merge request diff commit users' do
    it 'finds the existing user' do
      user = MergeRequest::DiffCommitUser.find_or_create('Alice', 'alice@example.com')

      found = described_class.build(
        MergeRequest::DiffCommitUser,
        'name' => 'Alice',
        'email' => 'alice@example.com'
      )

      expect(found).to eq(user)
    end

    it 'creates a new user' do
      found = described_class.build(
        MergeRequest::DiffCommitUser,
        'name' => 'Alice',
        'email' => 'alice@example.com'
      )

      expect(found.name).to eq('Alice')
      expect(found.email).to eq('alice@example.com')
    end
  end

  context 'merge request diff commits' do
    context 'when the "committer" object is present' do
      it 'uses this object as the committer' do
        user = MergeRequest::DiffCommitUser
          .find_or_create('Alice', 'alice@example.com')

        commit = described_class.build(
          MergeRequestDiffCommit,
          {
            'committer' => user,
            'committer_name' => 'Bla',
            'committer_email' => 'bla@example.com',
            'author_name' => 'Bla',
            'author_email' => 'bla@example.com'
          }
        )

        expect(commit.committer).to eq(user)
      end
    end

    context 'when the "committer" object is missing' do
      it 'creates one from the committer name and Email' do
        commit = described_class.build(
          MergeRequestDiffCommit,
          {
            'committer_name' => 'Alice',
            'committer_email' => 'alice@example.com',
            'author_name' => 'Alice',
            'author_email' => 'alice@example.com'
          }
        )

        expect(commit.committer.name).to eq('Alice')
        expect(commit.committer.email).to eq('alice@example.com')
      end
    end

    context 'when the "commit_author" object is present' do
      it 'uses this object as the author' do
        user = MergeRequest::DiffCommitUser
          .find_or_create('Alice', 'alice@example.com')

        commit = described_class.build(
          MergeRequestDiffCommit,
          {
            'committer_name' => 'Alice',
            'committer_email' => 'alice@example.com',
            'commit_author' => user,
            'author_name' => 'Bla',
            'author_email' => 'bla@example.com'
          }
        )

        expect(commit.commit_author).to eq(user)
      end
    end

    context 'when the "commit_author" object is missing' do
      it 'creates one from the author name and Email' do
        commit = described_class.build(
          MergeRequestDiffCommit,
          {
            'committer_name' => 'Alice',
            'committer_email' => 'alice@example.com',
            'author_name' => 'Alice',
            'author_email' => 'alice@example.com'
          }
        )

        expect(commit.commit_author.name).to eq('Alice')
        expect(commit.commit_author.email).to eq('alice@example.com')
      end
    end
  end

  describe '#find_or_create_diff_commit_user' do
    context 'when the user already exists' do
      it 'returns the existing user' do
        user = MergeRequest::DiffCommitUser
          .find_or_create('Alice', 'alice@example.com')

        found = described_class
          .new(MergeRequestDiffCommit, {})
          .send(:find_or_create_diff_commit_user, user.name, user.email)

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist' do
      it 'creates the user' do
        found = described_class
          .new(MergeRequestDiffCommit, {})
          .send(:find_or_create_diff_commit_user, 'Alice', 'alice@example.com')

        expect(found.name).to eq('Alice')
        expect(found.email).to eq('alice@example.com')
      end
    end

    it 'caches the results' do
      builder = described_class.new(MergeRequestDiffCommit, {})

      builder.send(:find_or_create_diff_commit_user, 'Alice', 'alice@example.com')

      record = ActiveRecord::QueryRecorder.new do
        builder.send(:find_or_create_diff_commit_user, 'Alice', 'alice@example.com')
      end

      expect(record.count).to eq(1)
    end
  end
end

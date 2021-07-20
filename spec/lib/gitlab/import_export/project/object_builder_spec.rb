# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::ObjectBuilder do
  let!(:group) { create(:group, :private) }
  let!(:subgroup) { create(:group, :private, parent: group) }
  let!(:project) do
    create(:project, :repository,
           :builds_disabled,
           :issues_disabled,
           name: 'project',
           path: 'project',
           group: subgroup)
  end

  let(:lru_cache) { subject.send(:lru_cache) }
  let(:cache_key) { subject.send(:cache_key) }

  context 'request store is not active' do
    subject do
      described_class.new(Label,
                          'title' => 'group label',
                          'project' => project,
                          'group' => project.group)
    end

    it 'ignore cache initialize' do
      expect(lru_cache).to be_nil
      expect(cache_key).to be_nil
    end
  end

  context 'request store is active', :request_store do
    subject do
      described_class.new(Label,
                          'title' => 'group label',
                          'project' => project,
                          'group' => project.group)
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

      expect(described_class.build(Label,
                                  'title' => 'group label',
                                  'project' => project,
                                  'group' => project.group)).to eq(group_label)
    end

    it 'finds the existing group label in root ancestor' do
      group_label = create(:group_label, name: 'group label', group: group)

      expect(described_class.build(Label,
                                   'title' => 'group label',
                                   'project' => project,
                                   'group' => group)).to eq(group_label)
    end

    it 'creates a new label' do
      label = described_class.build(Label,
                                   'title' => 'group label',
                                   'project' => project,
                                   'group' => project.group)

      expect(label.persisted?).to be true
    end
  end

  context 'milestones' do
    it 'finds the existing group milestone' do
      milestone = create(:milestone, name: 'group milestone', group: project.group)

      expect(described_class.build(Milestone,
                                  'title' => 'group milestone',
                                  'project' => project,
                                  'group' => project.group)).to eq(milestone)
    end

    it 'finds the existing group milestone in root ancestor' do
      milestone = create(:milestone, name: 'group milestone', group: group)

      expect(described_class.build(Milestone,
                                   'title' => 'group milestone',
                                   'project' => project,
                                   'group' => group)).to eq(milestone)
    end

    it 'creates a new milestone' do
      milestone = described_class.build(Milestone,
                                       'title' => 'group milestone',
                                       'project' => project,
                                       'group' => project.group)

      expect(milestone.persisted?).to be true
    end
  end

  context 'merge_request' do
    it 'finds the existing merge_request' do
      merge_request = create(:merge_request, title: 'MergeRequest', iid: 7, target_project: project, source_project: project)
      expect(described_class.build(MergeRequest,
                                   'title' => 'MergeRequest',
                                   'source_project_id' => project.id,
                                   'target_project_id' => project.id,
                                   'source_branch' => 'SourceBranch',
                                   'iid' => 7,
                                   'target_branch' => 'TargetBranch',
                                   'author_id' => project.creator.id)).to eq(merge_request)
    end

    it 'creates a new merge_request' do
      merge_request = described_class.build(MergeRequest,
                                            'title' => 'MergeRequest',
                                            'iid' => 8,
                                            'source_project_id' => project.id,
                                            'target_project_id' => project.id,
                                            'source_branch' => 'SourceBranch',
                                            'target_branch' => 'TargetBranch',
                                            'author_id' => project.creator.id)
      expect(merge_request.persisted?).to be true
    end
  end

  context 'merge request diff commit users' do
    it 'finds the existing user' do
      user = MergeRequest::DiffCommitUser
        .find_or_create('Alice', 'alice@example.com')

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
end

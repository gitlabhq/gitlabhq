# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::GroupProjectObjectBuilder do
  let(:project) do
    create(:project, :repository,
           :builds_disabled,
           :issues_disabled,
           name: 'project',
           path: 'project',
           group: create(:group))
  end

  context 'labels' do
    it 'finds the existing group label' do
      group_label = create(:group_label, name: 'group label', group: project.group)

      expect(described_class.build(Label,
                                  'title' => 'group label',
                                  'project' => project,
                                  'group' => project.group)).to eq(group_label)
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
end

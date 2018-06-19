require 'spec_helper'

describe Gitlab::ImportExport::GroupProjectFinder do
  let(:project) do
    create(:project,
           :builds_disabled,
           :issues_disabled,
           name: 'project',
           path: 'project',
           group: create(:group))
  end

  context 'labels' do
    it 'finds the right group label' do
      group_label = create(:group_label, 'name': 'group label', 'group': project.group)

      expect(described_class.find_or_new(Label,
                                         title: 'group label',
                                         'project_id' => project.id,
                                         'group_id' => project.group.id)).to eq(group_label)
    end

    it 'initializes a new label' do
      label = described_class.find_or_new(Label,
                                          title: 'group label',
                                          'project_id' => project.id,
                                          'group_id' => project.group.id)

      expect(label.persisted?).to be false
    end

    it 'creates a new label' do
      label = described_class.find_or_create(Label,
                                             title: 'group label',
                                             'project_id' => project.id,
                                             'group_id' => project.group.id)

      expect(label.persisted?).to be true
    end
  end

  context 'milestones' do
    it 'finds the right group milestone' do
      milestone = create(:milestone, 'name' => 'group milestone', 'group' => project.group)

      expect(described_class.find_or_new(Milestone,
                                         title: 'group milestone',
                                         'project_id' => project.id,
                                         'group_id' => project.group.id)).to eq(milestone)
    end

    it 'initializes a new milestone' do
      milestone = described_class.find_or_new(Milestone,
                                          title: 'group milestone',
                                          'project_id' => project.id,
                                          'group_id' => project.group.id)

      expect(milestone.persisted?).to be false
    end

    it 'creates a new milestone' do
      milestone = described_class.find_or_create(Milestone,
                                             title: 'group milestone',
                                             'project_id' => project.id,
                                             'group_id' => project.group.id)

      expect(milestone.persisted?).to be true
    end
  end
end

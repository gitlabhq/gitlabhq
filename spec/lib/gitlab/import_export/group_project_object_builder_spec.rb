require 'spec_helper'

describe Gitlab::ImportExport::GroupProjectObjectBuilder do
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
    it 'finds the right group milestone' do
      milestone = create(:milestone, 'name' => 'group milestone', 'group' => project.group)

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
end

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

  it 'finds the right group label' do
    group_label = create(:group_label, 'name': 'group label', 'group': project.group)

    expect(described_class.find(Label,
                                title: 'group label',
                                'project_id': project.id,
                                'group_id': project.group.id)).to eq([group_label])
  end
end

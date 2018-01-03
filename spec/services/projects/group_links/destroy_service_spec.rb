require 'spec_helper'

describe Projects::GroupLinks::DestroyService, '#execute' do
  let(:group_link) { create :project_group_link }
  let(:project) { group_link.project }
  let(:user) { create :user }
  let(:subject) { described_class.new(project, user) }

  it 'removes group from project' do
    expect { subject.execute(group_link) }.to change { project.project_group_links.count }.from(1).to(0)
  end

  it 'returns false if group_link is blank' do
    expect { subject.execute(nil) }.not_to change { project.project_group_links.count }
  end
end

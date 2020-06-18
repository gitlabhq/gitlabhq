# frozen_string_literal: true

require 'spec_helper'

describe Projects::GroupLinks::CreateService, '#execute' do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create :project }
  let(:opts) do
    {
      link_group_access: '30',
      expires_at: nil
    }
  end

  subject { described_class.new(project, user, opts) }

  before do
    group.add_developer(user)
  end

  it 'adds group to project' do
    expect { subject.execute(group) }.to change { project.project_group_links.count }.from(0).to(1)
  end

  it 'updates authorization' do
    expect { subject.execute(group) }.to(
      change { Ability.allowed?(user, :read_project, project) }
        .from(false).to(true))
  end

  it 'returns false if group is blank' do
    expect { subject.execute(nil) }.not_to change { project.project_group_links.count }
  end

  it 'returns error if user is not allowed to share with a group' do
    expect { subject.execute(create(:group)) }.not_to change { project.project_group_links.count }
  end
end

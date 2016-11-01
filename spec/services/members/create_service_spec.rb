require 'spec_helper'

describe Members::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:project_user) { create(:user) }

  before { project.team << [user, :master] }

  it 'adds user to members' do
    params = { user_ids: project_user.id.to_s, access_level: Gitlab::Access::GUEST }
    result = described_class.new(project, user, params).execute

    expect(result).to be_truthy
    expect(project.users).to include project_user
  end

  it 'adds no user to members' do
    params = { user_ids: '', access_level: Gitlab::Access::GUEST }
    result = described_class.new(project, user, params).execute

    expect(result).to be_falsey
    expect(project.users).not_to include project_user
  end
end

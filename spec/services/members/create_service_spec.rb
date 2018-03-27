require 'spec_helper'

describe Members::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:project_user) { create(:user) }

  before do
    project.add_master(user)
  end

  it 'adds user to members' do
    params = { user_ids: project_user.id.to_s, access_level: Gitlab::Access::GUEST }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:success)
    expect(project.users).to include project_user
  end

  it 'adds no user to members' do
    params = { user_ids: '', access_level: Gitlab::Access::GUEST }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:error)
    expect(result[:message]).to be_present
    expect(project.users).not_to include project_user
  end

  it 'limits the number of users to 100' do
    user_ids = 1.upto(101).to_a.join(',')
    params = { user_ids: user_ids, access_level: Gitlab::Access::GUEST }

    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:error)
    expect(result[:message]).to be_present
    expect(project.users).not_to include project_user
  end
end

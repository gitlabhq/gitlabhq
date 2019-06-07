# frozen_string_literal: true

require 'spec_helper'

describe Members::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:project_user) { create(:user) }

  before do
    project.add_maintainer(user)
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

  it 'does not add an invalid member' do
    params = { user_ids: project_user.id.to_s, access_level: -1 }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:error)
    expect(result[:message]).to include("#{project_user.username}: Access level is not included in the list")
    expect(project.users).not_to include project_user
  end

  it 'does not add a member with an existing invite' do
    invited_member = create(:project_member, :invited, project: project)

    params = { user_ids: invited_member.invite_email,
               access_level: Gitlab::Access::GUEST }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:error)
    expect(result[:message]).to eq('Invite email has already been taken')
  end
end

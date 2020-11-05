# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:project_user) { create(:user) }

  before do
    project.add_maintainer(user)
  end

  it 'adds an existing user to members' do
    params = { email: project_user.email.to_s, access_level: Gitlab::Access::GUEST }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:success)
    expect(project.users).to include project_user
  end

  it 'creates a new user for an unknown email address' do
    params = { email: 'email@example.org', access_level: Gitlab::Access::GUEST }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:success)
  end

  it 'limits the number of emails to 100' do
    emails = Array.new(101).map { |n| "email#{n}@example.com" }
    params = { email: emails, access_level: Gitlab::Access::GUEST }

    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:error)
    expect(result[:message]).to eq('Too many users specified (limit is 100)')
  end

  it 'does not invite an invalid email' do
    params = { email: project_user.id.to_s, access_level: Gitlab::Access::GUEST }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:error)
    expect(result[:message][project_user.id.to_s]).to eq("Invite email is invalid")
    expect(project.users).not_to include project_user
  end

  it 'does not invite to an invalid access level' do
    params = { email: project_user.email, access_level: -1 }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:error)
    expect(result[:message][project_user.email]).to eq("Access level is not included in the list")
  end

  it 'does not add a member with an existing invite' do
    invited_member = create(:project_member, :invited, project: project)

    params = { email: invited_member.invite_email,
               access_level: Gitlab::Access::GUEST }
    result = described_class.new(user, params).execute(project)

    expect(result[:status]).to eq(:error)
    expect(result[:message][invited_member.invite_email]).to eq("Member already invited to #{project.name}")
  end
end

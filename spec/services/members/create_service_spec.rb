# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::CreateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project_user) { create(:user) }
  let_it_be(:user_ids) { project_user.id.to_s }
  let_it_be(:access_level) { Gitlab::Access::GUEST }
  let(:params) { { user_ids: user_ids, access_level: access_level } }

  subject(:execute_service) { described_class.new(user, params).execute(project) }

  before do
    project.add_maintainer(user)
    allow(Namespaces::OnboardingUserAddedWorker).to receive(:idempotent?).and_return(false)
  end

  context 'when passing valid parameters' do
    it 'adds a user to members' do
      expect(execute_service[:status]).to eq(:success)
      expect(project.users).to include project_user
      expect(Namespaces::OnboardingUserAddedWorker.jobs.last['args'][0]).to eq(project.id)
    end
  end

  context 'when passing no user ids' do
    let(:user_ids) { '' }

    it 'does not add a member' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to be_present
      expect(project.users).not_to include project_user
      expect(Namespaces::OnboardingUserAddedWorker.jobs.size).to eq(0)
    end
  end

  context 'when passing many user ids' do
    let(:user_ids) { 1.upto(101).to_a.join(',') }

    it 'limits the number of users to 100' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to be_present
      expect(project.users).not_to include project_user
      expect(Namespaces::OnboardingUserAddedWorker.jobs.size).to eq(0)
    end
  end

  context 'when passing an invalid access level' do
    let(:access_level) { -1 }

    it 'does not add a member' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to include("#{project_user.username}: Access level is not included in the list")
      expect(project.users).not_to include project_user
      expect(Namespaces::OnboardingUserAddedWorker.jobs.size).to eq(0)
    end
  end

  context 'when passing an existing invite user id' do
    let(:user_ids) { create(:project_member, :invited, project: project).invite_email }

    it 'does not add a member' do
      expect(execute_service[:status]).to eq(:error)
      expect(execute_service[:message]).to eq('Invite email has already been taken')
      expect(Namespaces::OnboardingUserAddedWorker.jobs.size).to eq(0)
    end
  end
end

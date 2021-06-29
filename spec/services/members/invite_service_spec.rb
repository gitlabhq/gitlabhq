# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteService, :aggregate_failures, :clean_gitlab_redis_shared_state, :sidekiq_inline do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:project_user) { create(:user) }
  let_it_be(:namespace) { project.namespace }

  let(:params) { {} }
  let(:base_params) { { access_level: Gitlab::Access::GUEST, source: project, invite_source: '_invite_source_' } }

  subject(:result) { described_class.new(user, base_params.merge(params) ).execute }

  context 'when there is a valid member invited' do
    let(:params) { { email: 'email@example.org' } }

    it 'successfully creates a member' do
      expect_to_create_members(count: 1)
      expect(result[:status]).to eq(:success)
    end

    it_behaves_like 'records an onboarding progress action', :user_added
  end

  context 'when email belongs to an existing user as a secondary email' do
    let(:secondary_email) { create(:email, email: 'secondary@example.com', user: project_user) }
    let(:params) { { email: secondary_email.email } }

    it 'adds an existing user to members', :aggregate_failures do
      expect_to_create_members(count: 1)
      expect(result[:status]).to eq(:success)
      expect(project.users).to include project_user
      expect(project.members.last).not_to be_invite
    end
  end

  context 'when email is not a valid email' do
    let(:params) { { email: '_bogus_' } }

    it 'returns an error' do
      expect_not_to_create_members
      expect(result[:message]['_bogus_']).to eq("Invite email is invalid")
    end

    it_behaves_like 'does not record an onboarding progress action'
  end

  context 'when emails are passed as an array' do
    let(:params) { { email: %w[email@example.org email2@example.org] } }

    it 'successfully creates members' do
      expect_to_create_members(count: 2)
      expect(result[:status]).to eq(:success)
    end
  end

  context 'when emails are passed as an empty string' do
    let(:params) { { email: '' } }

    it 'returns an error' do
      expect_not_to_create_members
      expect(result[:message]).to eq('Emails cannot be blank')
    end
  end

  context 'when email param is not included' do
    it 'returns an error' do
      expect_not_to_create_members
      expect(result[:message]).to eq('Emails cannot be blank')
    end
  end

  context 'when email is not a valid email format' do
    let(:params) { { email: '_bogus_' } }

    it 'returns an error' do
      expect { result }.not_to change(ProjectMember, :count)
      expect(result[:status]).to eq(:error)
      expect(result[:message][params[:email]]).to eq("Invite email is invalid")
    end
  end

  context 'when duplicate email addresses are passed' do
    let(:params) { { email: 'email@example.org,email@example.org' } }

    it 'only creates one member per unique address' do
      expect_to_create_members(count: 1)
      expect(result[:status]).to eq(:success)
    end
  end

  context 'when observing email limits' do
    let_it_be(:emails) { Array(1..101).map { |n| "email#{n}@example.com" } }

    context 'when over the allowed default limit of emails' do
      let(:params) { { email: emails } }

      it 'limits the number of emails to 100' do
        expect_not_to_create_members
        expect(result[:message]).to eq('Too many users specified (limit is 100)')
      end
    end

    context 'when over the allowed custom limit of emails' do
      let(:params) { { email: 'email@example.org,email2@example.org', limit: 1 } }

      it 'limits the number of emails to the limit supplied' do
        expect_not_to_create_members
        expect(result[:message]).to eq('Too many users specified (limit is 1)')
      end
    end

    context 'when limit allowed is disabled via limit param' do
      let(:params) { { email: emails, limit: -1 } }

      it 'does not limit number of emails' do
        expect_to_create_members(count: 101)
        expect(result[:status]).to eq(:success)
      end
    end
  end

  context 'when email belongs to an existing user' do
    let(:params) { { email: project_user.email } }

    it 'adds an existing user to members' do
      expect_to_create_members(count: 1)
      expect(result[:status]).to eq(:success)
      expect(project.users).to include project_user
    end
  end

  context 'when access level is not valid' do
    let(:params) { { email: project_user.email, access_level: -1 } }

    it 'returns an error' do
      expect_not_to_create_members
      expect(result[:message][project_user.email])
        .to eq("Access level is not included in the list")
    end
  end

  context 'when invite already exists for an included email' do
    let!(:invited_member) { create(:project_member, :invited, project: project) }
    let(:params) { { email: "#{invited_member.invite_email},#{project_user.email}" } }

    it 'adds new email and returns an error for the already invited email' do
      expect_to_create_members(count: 1)
      expect(result[:status]).to eq(:error)
      expect(result[:message][invited_member.invite_email])
        .to eq("Invite email has already been taken")
      expect(project.users).to include project_user
    end
  end

  context 'when access request already exists for an included email' do
    let!(:requested_member) { create(:project_member, :access_request, project: project) }
    let(:params) { { email: "#{requested_member.user.email},#{project_user.email}" } }

    it 'adds new email and returns an error for the already invited email' do
      expect_to_create_members(count: 1)
      expect(result[:status]).to eq(:error)
      expect(result[:message][requested_member.user.email])
        .to eq("User already exists in source")
      expect(project.users).to include project_user
    end
  end

  context 'when email is already a member on the project' do
    let!(:existing_member) { create(:project_member, :guest, project: project) }
    let(:params) { { email: "#{existing_member.user.email},#{project_user.email}" } }

    it 'adds new email and returns an error for the already invited email' do
      expect_to_create_members(count: 1)
      expect(result[:status]).to eq(:error)
      expect(result[:message][existing_member.user.email])
        .to eq("User already exists in source")
      expect(project.users).to include project_user
    end
  end

  def expect_to_create_members(count:)
    expect { result }.to change(ProjectMember, :count).by(count)
  end

  def expect_not_to_create_members
    expect { result }.not_to change(ProjectMember, :count)
    expect(result[:status]).to eq(:error)
  end
end

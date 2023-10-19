# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::User do
  let_it_be(:timezone) { 'America/Los_Angeles' }

  let(:user) { create(:user, timezone: timezone) }
  let(:current_user) { create(:user) }
  let(:entity) { described_class.new(user, current_user: current_user) }

  subject { entity.as_json }

  it 'exposes correct attributes' do
    expect(subject.keys).to contain_exactly(
      # UserSafe
      :id, :username, :name,
      # UserBasic
      :state, :locked, :avatar_url, :web_url,
      # User
      :created_at, :bio, :location, :public_email, :skype, :linkedin, :twitter, :discord,
      :website_url, :organization, :job_title, :pronouns, :bot, :work_information,
      :followers, :following, :is_followed, :local_time
    )
  end

  context 'exposing follow relationships' do
    before do
      allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, user).and_return(can_read_user_profile)
    end

    %i[followers following is_followed].each do |relationship|
      shared_examples 'does not expose relationship' do
        it "does not expose #{relationship}" do
          expect(subject).not_to include(relationship)
        end
      end

      shared_examples 'exposes relationship' do
        it "exposes #{relationship}" do
          expect(subject).to include(relationship)
        end
      end

      context 'when current user cannot read user profile' do
        let(:can_read_user_profile) { false }

        it_behaves_like 'does not expose relationship'
      end

      context 'when current user can read user profile' do
        let(:can_read_user_profile) { true }

        it_behaves_like 'exposes relationship'
      end

      context 'when current user can read user profile and user disabled it for themself' do
        let(:can_read_user_profile) { true }

        before do
          user.enabled_following = false
          user.save!
        end

        it_behaves_like 'does not expose relationship'
      end

      context 'when current user can read user profile and current user disabled it for themself' do
        let(:can_read_user_profile) { true }

        before do
          current_user.enabled_following = false
          current_user.save!
        end

        it_behaves_like 'does not expose relationship'
      end
    end
  end

  it 'exposes created_at if the current user can read the user profile' do
    allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, user).and_return(true)

    expect(subject).to include(:created_at)
  end

  it 'does not expose created_at if the current user cannot read the user profile' do
    allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, user).and_return(false)

    expect(subject).not_to include(:created_at)
  end

  it 'exposes user as not a bot' do
    expect(subject[:bot]).to be_falsey
  end

  context 'with project bot user' do
    let(:project) { create(:project) }
    let(:user) { create(:user, :project_bot, name: 'secret') }

    before do
      project.add_maintainer(user)
    end

    it 'exposes user as a bot' do
      expect(subject[:bot]).to eq(true)
    end

    context 'when the requester is not an admin' do
      it 'does not expose project bot user name' do
        expect(subject[:name]).to eq('****')
      end
    end

    context 'when the requester is nil' do
      let(:current_user) { nil }

      it 'does not expose project bot user name' do
        expect(subject[:name]).to eq('****')
      end
    end

    context 'when the requester is a project maintainer' do
      let(:current_user) { create(:user) }

      before do
        project.add_maintainer(current_user)
      end

      it 'exposes project bot user name' do
        expect(subject[:name]).to eq('secret')
      end
    end

    context 'when the requester is an admin' do
      let(:current_user) { create(:user, :admin) }

      it 'exposes project bot user name', :enable_admin_mode do
        expect(subject[:name]).to eq('secret')
      end
    end
  end

  context 'with group bot user' do
    let(:group) { create(:group) }
    let(:user) { create(:user, :project_bot, name: 'group bot') }

    before do
      group.add_maintainer(user)
    end

    it 'exposes user as a bot' do
      expect(subject[:bot]).to eq(true)
    end

    context 'when the requester is not a group member' do
      context 'with a public group' do
        it 'exposes group bot user name' do
          expect(subject[:name]).to eq('group bot')
        end
      end

      context 'with a private group' do
        let(:group) { create(:group, :private) }

        it 'does not expose group bot user name' do
          expect(subject[:name]).to eq('****')
        end
      end
    end

    context 'when the requester is nil' do
      let(:current_user) { nil }

      it 'does not expose group bot user name' do
        expect(subject[:name]).to eq('****')
      end
    end

    context 'when the requester is a group maintainer' do
      let(:current_user) { create(:user) }

      before do
        group.add_maintainer(current_user)
      end

      it 'exposes group bot user name' do
        expect(subject[:name]).to eq('group bot')
      end
    end

    context 'when the requester is an admin' do
      let(:current_user) { create(:user, :admin) }

      it 'exposes group bot user name', :enable_admin_mode do
        expect(subject[:name]).to eq('group bot')
      end
    end
  end

  context 'with logged-out user' do
    let(:current_user) { nil }

    it 'exposes is_followed as nil' do
      allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, user).and_return(true)

      expect(subject.keys).not_to include(:is_followed)
    end
  end

  it 'exposes local_time' do
    local_time = '2:30 PM'
    expect(entity).to receive(:local_time).with(timezone).and_return(local_time)
    expect(subject[:local_time]).to eq(local_time)
  end
end

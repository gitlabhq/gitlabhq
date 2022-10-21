# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersStarProject, type: :model do
  it { is_expected.to belong_to(:project).touch(false) }

  describe 'scopes' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:user_active) { create(:user, state: 'active', name: 'user2', private_profile: true) }
    let_it_be(:user_blocked) { create(:user, state: 'blocked', name: 'user1') }

    let_it_be(:users_star_project1) { create(:users_star_project, project: project1, user: user_active) }
    let_it_be(:users_star_project2) { create(:users_star_project, project: project2, user: user_blocked) }

    describe '.all' do
      it 'returns all records' do
        expect(described_class.all).to contain_exactly(users_star_project1, users_star_project2)
      end
    end

    describe '.with_active_user' do
      it 'returns only records of active users' do
        expect(described_class.with_active_user).to contain_exactly(users_star_project1)
      end
    end

    describe '.order_user_name_asc' do
      it 'sorts records by ascending user name' do
        expect(described_class.order_user_name_asc).to eq([users_star_project2, users_star_project1])
      end
    end

    describe '.order_user_name_desc' do
      it 'sorts records by descending user name' do
        expect(described_class.order_user_name_desc).to eq([users_star_project1, users_star_project2])
      end
    end

    describe '.by_project' do
      it 'returns only records of given project' do
        expect(described_class.by_project(project2)).to contain_exactly(users_star_project2)
      end
    end

    describe '.with_public_profile' do
      it 'returns only records of users with public profile' do
        expect(described_class.with_public_profile).to contain_exactly(users_star_project2)
      end
    end
  end
end

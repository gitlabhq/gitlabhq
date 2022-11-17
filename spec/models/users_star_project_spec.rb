# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersStarProject, type: :model do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:user_active) { create(:user, state: 'active', name: 'user2', private_profile: true) }
  let_it_be(:user_blocked) { create(:user, state: 'blocked', name: 'user1') }

  it { is_expected.to belong_to(:project).touch(false) }

  describe 'scopes' do
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

  describe 'star count hooks' do
    context 'on after_create' do
      context 'if user is active' do
        it 'increments star count of project' do
          expect { user_active.toggle_star(project1) }.to change { project1.reload.star_count }.by(1)
        end
      end

      context 'if user is not active' do
        it 'does not increment star count of project' do
          expect { user_blocked.toggle_star(project1) }.not_to change { project1.reload.star_count }
        end
      end
    end

    context 'on after_destory' do
      context 'if user is active' do
        let_it_be(:users_star_project) { create(:users_star_project, project: project2, user: user_active) }

        it 'decrements star count of project' do
          expect { users_star_project.destroy! }.to change { project2.reload.star_count }.by(-1)
        end
      end

      context 'if user is not active' do
        let_it_be(:users_star_project) { create(:users_star_project, project: project2, user: user_blocked) }

        it 'does not decrement star count of project' do
          expect { users_star_project.destroy! }.not_to change { project2.reload.star_count }
        end
      end
    end
  end
end

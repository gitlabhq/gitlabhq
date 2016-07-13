require 'spec_helper'

describe Gitlab::UserAccess, lib: true do
  let(:access) { Gitlab::UserAccess.new(user, project: project) }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  describe 'can_push_to_branch?' do
    describe 'push to none protected branch' do
      it 'returns true if user is a master' do
        project.team << [user, :master]
        expect(access.can_push_to_branch?('random_branch')).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?('random_branch')).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?('random_branch')).to be_falsey
      end
    end

    describe 'push to protected branch' do
      let(:branch) { create :protected_branch, project: project }

      it 'returns true if user is a master' do
        project.team << [user, :master]
        expect(access.can_push_to_branch?(branch.name)).to be_truthy
      end

      it 'returns false if user is a developer' do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?(branch.name)).to be_falsey
      end

      it 'returns false if user is a reporter' do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?(branch.name)).to be_falsey
      end
    end

    describe 'push to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, project: project, developers_can_push: true
      end

      it 'returns true if user is a master' do
        project.team << [user, :master]
        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.team << [user, :developer]
        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.team << [user, :reporter]
        expect(access.can_push_to_branch?(@branch.name)).to be_falsey
      end
    end

    describe 'merge to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, project: project, developers_can_merge: true
      end

      it 'returns true if user is a master' do
        project.team << [user, :master]
        expect(access.can_merge_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.team << [user, :developer]
        expect(access.can_merge_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.team << [user, :reporter]
        expect(access.can_merge_to_branch?(@branch.name)).to be_falsey
      end
    end

  end
end

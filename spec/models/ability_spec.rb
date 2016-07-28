require 'spec_helper'

describe Ability, lib: true do
  describe '.can_edit_note?' do
    let(:project) { create(:empty_project) }
    let!(:note) { create(:note_on_issue, project: project) }

    context 'using an anonymous user' do
      it 'returns false' do
        expect(described_class.can_edit_note?(nil, note)).to be_falsy
      end
    end

    context 'using a system note' do
      it 'returns false' do
        system_note = create(:note, system: true)
        user = create(:user)

        expect(described_class.can_edit_note?(user, system_note)).to be_falsy
      end
    end

    context 'using users with different access levels' do
      let(:user) { create(:user) }

      it 'returns true for the author' do
        expect(described_class.can_edit_note?(note.author, note)).to be_truthy
      end

      it 'returns false for a guest user' do
        project.team << [user, :guest]

        expect(described_class.can_edit_note?(user, note)).to be_falsy
      end

      it 'returns false for a developer' do
        project.team << [user, :developer]

        expect(described_class.can_edit_note?(user, note)).to be_falsy
      end

      it 'returns true for a master' do
        project.team << [user, :master]

        expect(described_class.can_edit_note?(user, note)).to be_truthy
      end

      it 'returns true for a group owner' do
        group = create(:group)
        project.project_group_links.create(
          group: group,
          group_access: Gitlab::Access::MASTER)
        group.add_owner(user)

        expect(described_class.can_edit_note?(user, note)).to be_truthy
      end
    end
  end

  describe '.users_that_can_read_project' do
    context 'using a public project' do
      it 'returns all the users' do
        project = create(:project, :public)
        user = build(:user)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end
    end

    context 'using an internal project' do
      let(:project) { create(:project, :internal) }

      it 'returns users that are administrators' do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end

      it 'returns internal users while skipping external users' do
        user1 = build(:user)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are the project owner' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project).to receive(:owner).twice.and_return(user1)

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are project members' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project.team).to receive(:members).twice.and_return([user1])

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns an empty Array if all users are external users without access' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end
    end

    context 'using a private project' do
      let(:project) { create(:project, :private) }

      it 'returns users that are administrators' do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end

      it 'returns external users if they are the project owner' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project).to receive(:owner).twice.and_return(user1)

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are project members' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project.team).to receive(:members).twice.and_return([user1])

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns an empty Array if all users are internal users without access' do
        user1 = build(:user)
        user2 = build(:user)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end

      it 'returns an empty Array if all users are external users without access' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end
    end
  end
end

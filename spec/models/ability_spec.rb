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

  shared_examples_for ".project_abilities" do |enable_request_store|
    before do
      RequestStore.begin! if enable_request_store
    end

    after do
      if enable_request_store
        RequestStore.end!
        RequestStore.clear!
      end
    end

    describe '.project_abilities' do
      let!(:project) { create(:empty_project, :public) }
      let!(:user) { create(:user) }

      it 'returns permissions for admin user' do
        admin = create(:admin)

        results = described_class.project_abilities(admin, project)

        expect(results.count).to eq(74)
      end

      it 'returns permissions for an owner' do
        results = described_class.project_abilities(project.owner, project)

        expect(results.count).to eq(73)
      end

      it 'returns permissions for a master' do
        project.team << [user, :master]

        results = described_class.project_abilities(user, project)

        expect(results.count).to eq(64)
      end

      it 'returns permissions for a developer' do
        project.team << [user, :developer]

        results = described_class.project_abilities(user, project)

        expect(results.count).to eq(44)
      end

      it 'returns permissions for a guest' do
        project.team << [user, :guest]

        results = described_class.project_abilities(user, project)

        expect(results.count).to eq(21)
      end
    end
  end

  describe '.project_abilities with RequestStore' do
    it_behaves_like ".project_abilities", true
  end

  describe '.project_abilities without RequestStore' do
    it_behaves_like ".project_abilities", false
  end

  describe '.issues_readable_by_user' do
    context 'with an admin user' do
      it 'returns all given issues' do
        user = build(:user, admin: true)
        issue = build(:issue)

        expect(described_class.issues_readable_by_user([issue], user)).
          to eq([issue])
      end
    end

    context 'with a regular user' do
      it 'returns the issues readable by the user' do
        user = build(:user)
        issue = build(:issue)

        expect(issue).to receive(:readable_by?).with(user).and_return(true)

        expect(described_class.issues_readable_by_user([issue], user)).
          to eq([issue])
      end

      it 'returns an empty Array when no issues are readable' do
        user = build(:user)
        issue = build(:issue)

        expect(issue).to receive(:readable_by?).with(user).and_return(false)

        expect(described_class.issues_readable_by_user([issue], user)).to eq([])
      end
    end

    context 'without a regular user' do
      it 'returns issues that are publicly visible' do
        hidden_issue = build(:issue)
        visible_issue = build(:issue)

        expect(hidden_issue).to receive(:publicly_visible?).and_return(false)
        expect(visible_issue).to receive(:publicly_visible?).and_return(true)

        issues = described_class.
          issues_readable_by_user([hidden_issue, visible_issue])

        expect(issues).to eq([visible_issue])
      end
    end
  end
end

require 'spec_helper'

describe Member do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "Validation" do
    subject { described_class.new(access_level: Member::GUEST) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.all_values) }

    it_behaves_like 'an object with email-formated attributes', :invite_email do
      subject { build(:project_member) }
    end

    context "when an invite email is provided" do
      let(:member) { build(:project_member, invite_email: "user@example.com", user: nil) }

      it "doesn't require a user" do
        expect(member).to be_valid
      end

      it "requires a valid invite email" do
        member.invite_email = "nope"

        expect(member).not_to be_valid
      end

      it "requires a unique invite email scoped to this source" do
        create(:project_member, source: member.source, invite_email: member.invite_email)

        expect(member).not_to be_valid
      end

      it "is valid otherwise" do
        expect(member).to be_valid
      end
    end

    context "when an invite email is not provided" do
      let(:member) { build(:project_member) }

      it "requires a user" do
        member.user = nil

        expect(member).not_to be_valid
      end

      it "is valid otherwise" do
        expect(member).to be_valid
      end
    end
  end

  describe 'Scopes & finders' do
    before do
      project = create(:project, :public, :access_requestable)
      group = create(:group)
      @owner_user = create(:user).tap { |u| group.add_owner(u) }
      @owner = group.members.find_by(user_id: @owner_user.id)

      @master_user = create(:user).tap { |u| project.add_master(u) }
      @master = project.members.find_by(user_id: @master_user.id)

      @blocked_user = create(:user).tap do |u|
        project.add_master(u)
        project.add_developer(u)

        u.block!
      end
      @blocked_master = project.members.find_by(user_id: @blocked_user.id, access_level: Gitlab::Access::MASTER)
      @blocked_developer = project.members.find_by(user_id: @blocked_user.id, access_level: Gitlab::Access::DEVELOPER)

      @invited_member = create(:project_member, :developer,
                              project: project,
                              invite_token: '1234',
                              invite_email: 'toto1@example.com')

      accepted_invite_user = build(:user, state: :active)
      @accepted_invite_member = create(:project_member, :developer,
                                      project: project,
                                      invite_token: '1234',
                                      invite_email: 'toto2@example.com')
                                      .tap { |u| u.accept_invite!(accepted_invite_user) }

      requested_user = create(:user).tap { |u| project.request_access(u) }
      @requested_member = project.requesters.find_by(user_id: requested_user.id)

      accepted_request_user = create(:user).tap { |u| project.request_access(u) }
      @accepted_request_member = project.requesters.find_by(user_id: accepted_request_user.id).tap { |m| m.accept_request }
    end

    describe '.access_for_user_ids' do
      it 'returns the right access levels' do
        users = [@owner_user.id, @master_user.id, @blocked_user.id]
        expected = {
          @owner_user.id => Gitlab::Access::OWNER,
          @master_user.id => Gitlab::Access::MASTER
        }

        expect(described_class.access_for_user_ids(users)).to eq(expected)
      end
    end

    describe '.invite' do
      it { expect(described_class.invite).not_to include @master }
      it { expect(described_class.invite).to include @invited_member }
      it { expect(described_class.invite).not_to include @accepted_invite_member }
      it { expect(described_class.invite).not_to include @requested_member }
      it { expect(described_class.invite).not_to include @accepted_request_member }
    end

    describe '.non_invite' do
      it { expect(described_class.non_invite).to include @master }
      it { expect(described_class.non_invite).not_to include @invited_member }
      it { expect(described_class.non_invite).to include @accepted_invite_member }
      it { expect(described_class.non_invite).to include @requested_member }
      it { expect(described_class.non_invite).to include @accepted_request_member }
    end

    describe '.request' do
      it { expect(described_class.request).not_to include @master }
      it { expect(described_class.request).not_to include @invited_member }
      it { expect(described_class.request).not_to include @accepted_invite_member }
      it { expect(described_class.request).to include @requested_member }
      it { expect(described_class.request).not_to include @accepted_request_member }
    end

    describe '.non_request' do
      it { expect(described_class.non_request).to include @master }
      it { expect(described_class.non_request).to include @invited_member }
      it { expect(described_class.non_request).to include @accepted_invite_member }
      it { expect(described_class.non_request).not_to include @requested_member }
      it { expect(described_class.non_request).to include @accepted_request_member }
    end

    describe '.developers' do
      subject { described_class.developers.to_a }

      it { is_expected.not_to include @owner }
      it { is_expected.not_to include @master }
      it { is_expected.to include @invited_member }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.not_to include @blocked_master }
      it { is_expected.not_to include @blocked_developer }
    end

    describe '.owners_and_masters' do
      it { expect(described_class.owners_and_masters).to include @owner }
      it { expect(described_class.owners_and_masters).to include @master }
      it { expect(described_class.owners_and_masters).not_to include @invited_member }
      it { expect(described_class.owners_and_masters).not_to include @accepted_invite_member }
      it { expect(described_class.owners_and_masters).not_to include @requested_member }
      it { expect(described_class.owners_and_masters).not_to include @accepted_request_member }
      it { expect(described_class.owners_and_masters).not_to include @blocked_master }
    end

    describe '.has_access' do
      subject { described_class.has_access.to_a }

      it { is_expected.to include @owner }
      it { is_expected.to include @master }
      it { is_expected.to include @invited_member }
      it { is_expected.to include @accepted_invite_member }
      it { is_expected.not_to include @requested_member }
      it { is_expected.to include @accepted_request_member }
      it { is_expected.not_to include @blocked_master }
      it { is_expected.not_to include @blocked_developer }
    end
  end

  describe "Delegate methods" do
    it { is_expected.to respond_to(:user_name) }
    it { is_expected.to respond_to(:user_email) }
  end

  describe '.add_user' do
    %w[project group].each do |source_type|
      context "when source is a #{source_type}" do
        let!(:source) { create(source_type, :public, :access_requestable) }
        let!(:user) { create(:user) }
        let!(:admin) { create(:admin) }

        it 'returns a <Source>Member object' do
          member = described_class.add_user(source, user, :master)

          expect(member).to be_a "#{source_type.classify}Member".constantize
          expect(member).to be_persisted
        end

        it 'sets members.created_by to the given current_user' do
          member = described_class.add_user(source, user, :master, current_user: admin)

          expect(member.created_by).to eq(admin)
        end

        it 'sets members.expires_at to the given expires_at' do
          member = described_class.add_user(source, user, :master, expires_at: Date.new(2016, 9, 22))

          expect(member.expires_at).to eq(Date.new(2016, 9, 22))
        end

        described_class.access_levels.each do |sym_key, int_access_level|
          it "accepts the :#{sym_key} symbol as access level" do
            expect(source.users).not_to include(user)

            member = described_class.add_user(source, user.id, sym_key)

            expect(member.access_level).to eq(int_access_level)
            expect(source.users.reload).to include(user)
          end

          it "accepts the #{int_access_level} integer as access level" do
            expect(source.users).not_to include(user)

            member = described_class.add_user(source, user.id, int_access_level)

            expect(member.access_level).to eq(int_access_level)
            expect(source.users.reload).to include(user)
          end
        end

        context 'with no current_user' do
          context 'when called with a known user id' do
            it 'adds the user as a member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, user.id, :master)

              expect(source.users.reload).to include(user)
            end
          end

          context 'when called with an unknown user id' do
            it 'adds the user as a member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, 42, :master)

              expect(source.users.reload).not_to include(user)
            end
          end

          context 'when called with a user object' do
            it 'adds the user as a member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, user, :master)

              expect(source.users.reload).to include(user)
            end
          end

          context 'when called with a requester user object' do
            before do
              source.request_access(user)
            end

            it 'adds the requester as a member' do
              expect(source.users).not_to include(user)
              expect(source.requesters.exists?(user_id: user)).to be_truthy

              expect { described_class.add_user(source, user, :master) }
                .to raise_error(Gitlab::Access::AccessDeniedError)

              expect(source.users.reload).not_to include(user)
              expect(source.requesters.reload.exists?(user_id: user)).to be_truthy
            end
          end

          context 'when called with a known user email' do
            it 'adds the user as a member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, user.email, :master)

              expect(source.users.reload).to include(user)
            end
          end

          context 'when called with an unknown user email' do
            it 'creates an invited member' do
              expect(source.users).not_to include(user)

              described_class.add_user(source, 'user@example.com', :master)

              expect(source.members.invite.pluck(:invite_email)).to include('user@example.com')
            end
          end
        end

        context 'when current_user can update member' do
          it 'creates the member' do
            expect(source.users).not_to include(user)

            described_class.add_user(source, user, :master, current_user: admin)

            expect(source.users.reload).to include(user)
          end

          context 'when called with a requester user object' do
            before do
              source.request_access(user)
            end

            it 'adds the requester as a member' do
              expect(source.users).not_to include(user)
              expect(source.requesters.exists?(user_id: user)).to be_truthy

              described_class.add_user(source, user, :master, current_user: admin)

              expect(source.users.reload).to include(user)
              expect(source.requesters.reload.exists?(user_id: user)).to be_falsy
            end
          end
        end

        context 'when current_user cannot update member' do
          it 'does not create the member' do
            expect(source.users).not_to include(user)

            member = described_class.add_user(source, user, :master, current_user: user)

            expect(source.users.reload).not_to include(user)
            expect(member).not_to be_persisted
          end

          context 'when called with a requester user object' do
            before do
              source.request_access(user)
            end

            it 'does not destroy the requester' do
              expect(source.users).not_to include(user)
              expect(source.requesters.exists?(user_id: user)).to be_truthy

              described_class.add_user(source, user, :master, current_user: user)

              expect(source.users.reload).not_to include(user)
              expect(source.requesters.exists?(user_id: user)).to be_truthy
            end
          end
        end

        context 'when member already exists' do
          before do
            source.add_user(user, :developer)
          end

          context 'with no current_user' do
            it 'updates the member' do
              expect(source.users).to include(user)

              described_class.add_user(source, user, :master)

              expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::MASTER)
            end
          end

          context 'when current_user can update member' do
            it 'updates the member' do
              expect(source.users).to include(user)

              described_class.add_user(source, user, :master, current_user: admin)

              expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::MASTER)
            end
          end

          context 'when current_user cannot update member' do
            it 'does not update the member' do
              expect(source.users).to include(user)

              described_class.add_user(source, user, :master, current_user: user)

              expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::DEVELOPER)
            end
          end
        end
      end
    end
  end

  describe '.add_users' do
    %w[project group].each do |source_type|
      context "when source is a #{source_type}" do
        let!(:source) { create(source_type, :public, :access_requestable) }
        let!(:admin) { create(:admin) }
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }

        it 'returns a <Source>Member objects' do
          members = described_class.add_users(source, [user1, user2], :master)

          expect(members).to be_a Array
          expect(members.size).to eq(2)
          expect(members.first).to be_a "#{source_type.classify}Member".constantize
          expect(members.first).to be_persisted
        end

        it 'returns an empty array' do
          members = described_class.add_users(source, [], :master)

          expect(members).to be_a Array
          expect(members).to be_empty
        end

        it 'supports differents formats' do
          list = ['joe@local.test', admin, user1.id, user2.id.to_s]

          members = described_class.add_users(source, list, :master)

          expect(members.size).to eq(4)
          expect(members.first).to be_invite
        end
      end
    end
  end

  describe '#accept_request' do
    let(:member) { create(:project_member, requested_at: Time.now.utc) }

    it { expect(member.accept_request).to be_truthy }

    it 'clears requested_at' do
      member.accept_request

      expect(member.requested_at).to be_nil
    end

    it 'calls #after_accept_request' do
      expect(member).to receive(:after_accept_request)

      member.accept_request
    end
  end

  describe '#invite?' do
    subject { create(:project_member, invite_email: "user@example.com", user: nil) }

    it { is_expected.to be_invite }
  end

  describe '#request?' do
    subject { create(:project_member, requested_at: Time.now.utc) }

    it { is_expected.to be_request }
  end

  describe '#pending?' do
    let(:invited_member) { create(:project_member, invite_email: "user@example.com", user: nil) }
    let(:requester) { create(:project_member, requested_at: Time.now.utc) }

    it { expect(invited_member).to be_invite }
    it { expect(requester).to be_pending }
  end

  describe "#accept_invite!" do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }
    let(:user) { create(:user) }

    it "resets the invite token" do
      member.accept_invite!(user)

      expect(member.invite_token).to be_nil
    end

    it "sets the invite accepted timestamp" do
      member.accept_invite!(user)

      expect(member.invite_accepted_at).not_to be_nil
    end

    it "sets the user" do
      member.accept_invite!(user)

      expect(member.user).to eq(user)
    end

    it "calls #after_accept_invite" do
      expect(member).to receive(:after_accept_invite)

      member.accept_invite!(user)
    end

    it "refreshes user's authorized projects", :delete do
      project = member.source

      expect(user.authorized_projects).not_to include(project)

      member.accept_invite!(user)

      expect(user.authorized_projects.reload).to include(project)
    end
  end

  describe "#decline_invite!" do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }

    it "destroys the member" do
      member.decline_invite!

      expect(member).to be_destroyed
    end

    it "calls #after_decline_invite" do
      expect(member).to receive(:after_decline_invite)

      member.decline_invite!
    end
  end

  describe "#generate_invite_token" do
    let!(:member) { create(:project_member, invite_email: "user@example.com", user: nil) }

    it "sets the invite token" do
      expect { member.generate_invite_token }.to change { member.invite_token}
    end
  end

  describe "destroying a record", :delete do
    it "refreshes user's authorized projects" do
      project = create(:project, :private)
      user    = create(:user)
      member  = project.add_reporter(user)

      member.destroy

      expect(user.authorized_projects).not_to include(project)
    end
  end
end

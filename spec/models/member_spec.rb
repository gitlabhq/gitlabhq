require 'spec_helper'

describe Member, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "Validation" do
    subject { Member.new(access_level: Member::GUEST) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.values) }

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
      project = create(:empty_project)
      group = create(:group)
      @owner_user = create(:user).tap { |u| group.add_owner(u) }
      @owner = group.members.find_by(user_id: @owner_user.id)

      @master_user = create(:user).tap { |u| project.team << [u, :master] }
      @master = project.members.find_by(user_id: @master_user.id)

      @blocked_user = create(:user).tap do |u|
        project.team << [u, :master]
        project.team << [u, :developer]

        u.block!
      end
      @blocked_master = project.members.find_by(user_id: @blocked_user.id, access_level: Gitlab::Access::MASTER)
      @blocked_developer = project.members.find_by(user_id: @blocked_user.id, access_level: Gitlab::Access::DEVELOPER)

      Member.add_user(
        project.members,
        'toto1@example.com',
        Gitlab::Access::DEVELOPER,
        @master_user
      )
      @invited_member = project.members.invite.find_by_invite_email('toto1@example.com')

      accepted_invite_user = build(:user, state: :active)
      Member.add_user(
        project.members,
        'toto2@example.com',
        Gitlab::Access::DEVELOPER,
        @master_user
      )
      @accepted_invite_member = project.members.invite.find_by_invite_email('toto2@example.com').tap { |u| u.accept_invite!(accepted_invite_user) }

      requested_user = create(:user).tap { |u| project.request_access(u) }
      @requested_member = project.requesters.find_by(user_id: requested_user.id)

      accepted_request_user = create(:user).tap { |u| project.request_access(u) }
      @accepted_request_member = project.requesters.find_by(user_id: accepted_request_user.id).tap { |m| m.accept_request }
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

  describe ".add_user" do
    let!(:user)    { create(:user) }
    let(:project) { create(:project) }

    context "when called with a user id" do
      it "adds the user as a member" do
        Member.add_user(project.project_members, user.id, ProjectMember::MASTER)

        expect(project.users).to include(user)
      end
    end

    context "when called with a user object" do
      it "adds the user as a member" do
        Member.add_user(project.project_members, user, ProjectMember::MASTER)

        expect(project.users).to include(user)
      end
    end

    context "when called with a known user email" do
      it "adds the user as a member" do
        Member.add_user(project.project_members, user.email, ProjectMember::MASTER)

        expect(project.users).to include(user)
      end
    end

    context "when called with an unknown user email" do
      it "adds a member invite" do
        Member.add_user(project.project_members, "user@example.com", ProjectMember::MASTER)

        expect(project.project_members.invite.pluck(:invite_email)).to include("user@example.com")
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
end

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

  describe 'Scopes' do
    before do
      project = create(:project)
      @invited_member = build(:project_member, user: nil).tap { |m| m.generate_invite_token! }
      @accepted_invite_member = build(:project_member, user: nil).tap { |m| m.generate_invite_token! && m.accept_invite!(build(:user)) }

      requested_user = create(:user).tap { |u| project.request_access(u) }
      @requested_member = project.project_members.find_by(created_by_id: requested_user.id)
      accepted_request_user = create(:user).tap { |u| project.request_access(u) }
      @accepted_request_member = project.project_members.find_by(created_by_id: accepted_request_user.id).tap { |m| m.accept_request }
    end

    describe '#invite' do
      it { expect(described_class.invite).to include @invited_member }
      it { expect(described_class.invite).not_to include @accepted_invite_member }
      it { expect(described_class.invite).not_to include @requested_member }
      it { expect(described_class.invite).not_to include @accepted_request_member }
    end

    describe '#request' do
      it { expect(described_class.request).not_to include @invited_member }
      it { expect(described_class.request).not_to include @accepted_invite_member }
      it { expect(described_class.request).to include @requested_member }
      it { expect(described_class.request).not_to include @accepted_request_member }
    end

    describe '#non_request' do
      it { expect(described_class.non_request).to include @invited_member }
      it { expect(described_class.non_request).to include @accepted_invite_member }
      it { expect(described_class.non_request).not_to include @requested_member }
      it { expect(described_class.non_request).to include @accepted_request_member }
    end

    describe '#non_pending' do
      it { expect(described_class.non_pending).not_to include @invited_member }
      it { expect(described_class.non_pending).to include @accepted_invite_member }
      it { expect(described_class.non_pending).not_to include @requested_member }
      it { expect(described_class.non_pending).to include @accepted_request_member }
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
    let(:user) { create(:user) }
    let(:member) { create(:project_member, requested_at: Time.now.utc, user: nil, created_by: user) }

    it 'returns true' do
      expect(member.accept_request).to be_truthy
    end

    it 'sets the user' do
      member.accept_request

      expect(member.user).to eq(user)
    end

    it 'clears requested_at' do
      member.accept_request

      expect(member.requested_at).to be_nil
    end

    it 'calls #after_accept_request' do
      expect(member).to receive(:after_accept_request)

      member.accept_request
    end
  end

  describe '#decline_request' do
    let(:user) { create(:user) }
    let(:member) { create(:project_member, requested_at: Time.now.utc, user: nil, created_by: user) }

    it 'returns true' do
      expect(member.decline_request).to be_truthy
    end

    it 'destroys the member' do
      member.decline_request

      expect(member).to be_destroyed
    end

    it 'calls #after_decline_request' do
      expect(member).to receive(:after_decline_request)

      member.decline_request
    end
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

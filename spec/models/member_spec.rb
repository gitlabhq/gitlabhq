# == Schema Information
#
# Table name: members
#
#  id                 :integer          not null, primary key
#  access_level       :integer          not null
#  source_id          :integer          not null
#  source_type        :string(255)      not null
#  user_id            :integer
#  notification_level :integer          not null
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  created_by_id      :integer
#  invite_email       :string(255)
#  invite_token       :string(255)
#  invite_accepted_at :datetime
#

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

require 'spec_helper'

describe ProtectedBranch, models: true do
  subject { build_stubbed(:protected_branch) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe "Uniqueness validations" do
    [ProtectedBranch::MergeAccessLevel, ProtectedBranch::PushAccessLevel].each do |access_level_class|
      let(:user) { create(:user) }
      let(:factory_name) { access_level_class.to_s.underscore.sub('/', '_').to_sym }
      let(:association_name) { access_level_class.to_s.underscore.sub('protected_branch/', '').pluralize.to_sym }
      human_association_name = access_level_class.to_s.underscore.humanize.sub('Protected branch/', '')

      context "while checking uniqueness of a role-based #{human_association_name}" do
        it "allows a single #{human_association_name} for a role (per protected branch)" do
          first_protected_branch = create(:protected_branch, :remove_default_access_levels)
          second_protected_branch = create(:protected_branch, :remove_default_access_levels)

          first_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)
          second_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)

          expect(first_protected_branch).to be_valid
          expect(second_protected_branch).to be_valid

          first_protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)
          expect(first_protected_branch).to be_invalid
          expect(first_protected_branch.errors.full_messages.first).to match("access level has already been taken")
        end

        it "does not count a user-based #{human_association_name} with an `access_level` set" do
          protected_branch = create(:protected_branch, :remove_default_access_levels)

          protected_branch.send(association_name) << build(factory_name, user: user, access_level: Gitlab::Access::MASTER)
          protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)

          expect(protected_branch).to be_valid
        end
      end


      context "while checking uniqueness of a user-based #{human_association_name}" do
        it "allows a single #{human_association_name} for a user (per protected branch)" do
          first_protected_branch = create(:protected_branch, :remove_default_access_levels)
          second_protected_branch = create(:protected_branch, :remove_default_access_levels)

          first_protected_branch.send(association_name) << build(factory_name, user: user)
          second_protected_branch.send(association_name) << build(factory_name, user: user)

          expect(first_protected_branch).to be_valid
          expect(second_protected_branch).to be_valid

          first_protected_branch.send(association_name) << build(factory_name, user: user)
          expect(first_protected_branch).to be_invalid
          expect(first_protected_branch.errors.full_messages.first).to match("user has already been taken")
        end

        it "ignores the `access_level` while validating a user-based #{human_association_name}" do
          protected_branch = create(:protected_branch, :remove_default_access_levels)

          protected_branch.send(association_name) << build(factory_name, access_level: Gitlab::Access::MASTER)
          protected_branch.send(association_name) << build(factory_name, user: user, access_level: Gitlab::Access::MASTER)

          expect(protected_branch).to be_valid
        end
      end
    end
  end

  describe "Mass assignment" do
  end

  describe 'Validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "#matches?" do
    context "when the protected branch setting is not a wildcard" do
      let(:protected_branch) { build(:protected_branch, name: "production/some-branch") }

      it "returns true for branch names that are an exact match" do
        expect(protected_branch.matches?("production/some-branch")).to be true
      end

      it "returns false for branch names that are not an exact match" do
        expect(protected_branch.matches?("staging/some-branch")).to be false
      end
    end

    context "when the protected branch name contains wildcard(s)" do
      context "when there is a single '*'" do
        let(:protected_branch) { build(:protected_branch, name: "production/*") }

        it "returns true for branch names matching the wildcard" do
          expect(protected_branch.matches?("production/some-branch")).to be true
          expect(protected_branch.matches?("production/")).to be true
        end

        it "returns false for branch names not matching the wildcard" do
          expect(protected_branch.matches?("staging/some-branch")).to be false
          expect(protected_branch.matches?("production")).to be false
        end
      end

      context "when the wildcard contains regex symbols other than a '*'" do
        let(:protected_branch) { build(:protected_branch, name: "pro.duc.tion/*") }

        it "returns true for branch names matching the wildcard" do
          expect(protected_branch.matches?("pro.duc.tion/some-branch")).to be true
        end

        it "returns false for branch names not matching the wildcard" do
          expect(protected_branch.matches?("production/some-branch")).to be false
          expect(protected_branch.matches?("proXducYtion/some-branch")).to be false
        end
      end

      context "when there are '*'s at either end" do
        let(:protected_branch) { build(:protected_branch, name: "*/production/*") }

        it "returns true for branch names matching the wildcard" do
          expect(protected_branch.matches?("gitlab/production/some-branch")).to be true
          expect(protected_branch.matches?("/production/some-branch")).to be true
          expect(protected_branch.matches?("gitlab/production/")).to be true
          expect(protected_branch.matches?("/production/")).to be true
        end

        it "returns false for branch names not matching the wildcard" do
          expect(protected_branch.matches?("gitlabproductionsome-branch")).to be false
          expect(protected_branch.matches?("production/some-branch")).to be false
          expect(protected_branch.matches?("gitlab/production")).to be false
          expect(protected_branch.matches?("production")).to be false
        end
      end

      context "when there are arbitrarily placed '*'s" do
        let(:protected_branch) { build(:protected_branch, name: "pro*duction/*/gitlab/*") }

        it "returns true for branch names matching the wildcard" do
          expect(protected_branch.matches?("production/some-branch/gitlab/second-branch")).to be true
          expect(protected_branch.matches?("proXYZduction/some-branch/gitlab/second-branch")).to be true
          expect(protected_branch.matches?("proXYZduction/gitlab/gitlab/gitlab")).to be true
          expect(protected_branch.matches?("proXYZduction//gitlab/")).to be true
          expect(protected_branch.matches?("proXYZduction/some-branch/gitlab/")).to be true
          expect(protected_branch.matches?("proXYZduction//gitlab/some-branch")).to be true
        end

        it "returns false for branch names not matching the wildcard" do
          expect(protected_branch.matches?("production/some-branch/not-gitlab/second-branch")).to be false
          expect(protected_branch.matches?("prodXYZuction/some-branch/gitlab/second-branch")).to be false
          expect(protected_branch.matches?("proXYZduction/gitlab/some-branch/gitlab")).to be false
          expect(protected_branch.matches?("proXYZduction/gitlab//")).to be false
          expect(protected_branch.matches?("proXYZduction/gitlab/")).to be false
          expect(protected_branch.matches?("proXYZduction//some-branch/gitlab")).to be false
        end
      end
    end
  end

  describe "#matching" do
    context "for direct matches" do
      it "returns a list of protected branches matching the given branch name" do
        production = create(:protected_branch, name: "production")
        staging = create(:protected_branch, name: "staging")

        expect(ProtectedBranch.matching("production")).to include(production)
        expect(ProtectedBranch.matching("production")).not_to include(staging)
      end

      it "accepts a list of protected branches to search from, so as to avoid a DB call" do
        production = build(:protected_branch, name: "production")
        staging = build(:protected_branch, name: "staging")

        expect(ProtectedBranch.matching("production")).to be_empty
        expect(ProtectedBranch.matching("production", protected_branches: [production, staging])).to include(production)
        expect(ProtectedBranch.matching("production", protected_branches: [production, staging])).not_to include(staging)
      end
    end

    context "for wildcard matches" do
      it "returns a list of protected branches matching the given branch name" do
        production = create(:protected_branch, name: "production/*")
        staging = create(:protected_branch, name: "staging/*")

        expect(ProtectedBranch.matching("production/some-branch")).to include(production)
        expect(ProtectedBranch.matching("production/some-branch")).not_to include(staging)
      end

      it "accepts a list of protected branches to search from, so as to avoid a DB call" do
        production = build(:protected_branch, name: "production/*")
        staging = build(:protected_branch, name: "staging/*")

        expect(ProtectedBranch.matching("production/some-branch")).to be_empty
        expect(ProtectedBranch.matching("production/some-branch", protected_branches: [production, staging])).to include(production)
        expect(ProtectedBranch.matching("production/some-branch", protected_branches: [production, staging])).not_to include(staging)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranch do
  subject { build_stubbed(:protected_branch) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
  end

  describe 'Validation' do
    it { is_expected.to validate_presence_of(:name) }

    describe '#validate_either_project_or_top_group' do
      context 'when protected branch does not have project or group association' do
        it 'validate failed' do
          subject.assign_attributes(project: nil, group: nil)
          subject.validate

          expect(subject.errors).to include(:base)
        end
      end

      context 'when protected branch is associated with both project and group' do
        it 'validate failed' do
          subject.assign_attributes(project: build(:project), group: build(:group))
          subject.validate

          expect(subject.errors).to include(:base)
        end
      end

      context 'when protected branch is associated with a subgroup' do
        it 'validate failed' do
          subject.assign_attributes(project: nil, group: build(:group, :nested))
          subject.validate

          expect(subject.errors).to include(:base)
        end
      end
    end
  end

  describe 'set a group' do
    context 'when associated with group' do
      it 'create successfully' do
        expect { subject.group = build(:group) }.not_to raise_error
      end
    end

    context 'when associated with other namespace' do
      it 'create failed with `ActiveRecord::AssociationTypeMismatch`' do
        expect { subject.group = build(:namespace) }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      end
    end
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

        expect(described_class.matching("production")).to include(production)
        expect(described_class.matching("production")).not_to include(staging)
      end

      it "accepts a list of protected branches to search from, so as to avoid a DB call" do
        production = build(:protected_branch, name: "production")
        staging = build(:protected_branch, name: "staging")

        expect(described_class.matching("production")).to be_empty
        expect(described_class.matching("production", protected_refs: [production, staging])).to include(production)
        expect(described_class.matching("production", protected_refs: [production, staging])).not_to include(staging)
      end
    end

    context "for wildcard matches" do
      it "returns a list of protected branches matching the given branch name" do
        production = create(:protected_branch, name: "production/*")
        staging = create(:protected_branch, name: "staging/*")

        expect(described_class.matching("production/some-branch")).to include(production)
        expect(described_class.matching("production/some-branch")).not_to include(staging)
      end

      it "accepts a list of protected branches to search from, so as to avoid a DB call" do
        production = build(:protected_branch, name: "production/*")
        staging = build(:protected_branch, name: "staging/*")

        expect(described_class.matching("production/some-branch")).to be_empty
        expect(described_class.matching("production/some-branch", protected_refs: [production, staging])).to include(production)
        expect(described_class.matching("production/some-branch", protected_refs: [production, staging])).not_to include(staging)
      end
    end
  end

  describe '#protected?' do
    context 'existing project' do
      let(:project) { create(:project, :repository) }

      it 'returns true when the branch matches a protected branch via direct match' do
        create(:protected_branch, project: project, name: "foo")

        expect(described_class.protected?(project, 'foo')).to eq(true)
      end

      it 'returns true when the branch matches a protected branch via wildcard match' do
        create(:protected_branch, project: project, name: "production/*")

        expect(described_class.protected?(project, 'production/some-branch')).to eq(true)
      end

      it 'returns false when the branch does not match a protected branch via direct match' do
        expect(described_class.protected?(project, 'foo')).to eq(false)
      end

      it 'returns false when the branch does not match a protected branch via wildcard match' do
        create(:protected_branch, project: project, name: "production/*")

        expect(described_class.protected?(project, 'staging/some-branch')).to eq(false)
      end

      it 'returns false when branch name is nil' do
        expect(described_class.protected?(project, nil)).to eq(false)
      end

      context 'with caching', :use_clean_rails_redis_caching do
        let_it_be(:project) { create(:project, :repository) }
        let_it_be(:protected_branch) { create(:protected_branch, project: project, name: "“jawn”") }

        let(:rely_on_new_cache) { true }

        shared_examples_for 'hash based cache implementation' do
          it 'calls only hash based cache implementation' do
            expect_next_instance_of(ProtectedBranches::CacheService) do |instance|
              expect(instance).to receive(:fetch).with('missing-branch', anything).and_call_original
            end

            expect(Rails.cache).not_to receive(:fetch)

            described_class.protected?(project, 'missing-branch')
          end
        end

        before do
          stub_feature_flags(rely_on_protected_branches_cache: rely_on_new_cache)
          allow(described_class).to receive(:matching).and_call_original

          # the original call works and warms the cache
          described_class.protected?(project, protected_branch.name)
        end

        context 'Dry-run: true (rely_on_protected_branches_cache is off, new hash-based is used)' do
          let(:rely_on_new_cache) { false }

          it 'recalculates a fresh value every time in order to check the cache is not returning stale data' do
            expect(described_class).to receive(:matching).with(protected_branch.name, protected_refs: anything).twice

            2.times { described_class.protected?(project, protected_branch.name) }
          end

          it_behaves_like 'hash based cache implementation'
        end

        context 'Dry-run: false (rely_on_protected_branches_cache is enabled, new hash-based cache is used)' do
          let(:rely_on_new_cache) { true }

          it 'correctly invalidates a cache' do
            expect(described_class).to receive(:matching).with(protected_branch.name, protected_refs: anything).exactly(3).times.and_call_original

            create_params = { name: 'bar', merge_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }] }
            branch = ProtectedBranches::CreateService.new(project, project.owner, create_params).execute
            expect(described_class.protected?(project, protected_branch.name)).to eq(true)

            ProtectedBranches::UpdateService.new(project, project.owner, name: 'ber').execute(branch)
            expect(described_class.protected?(project, protected_branch.name)).to eq(true)

            ProtectedBranches::DestroyService.new(project, project.owner).execute(branch)
            expect(described_class.protected?(project, protected_branch.name)).to eq(true)
          end

          it_behaves_like 'hash based cache implementation'

          context 'when project is updated' do
            it 'does not invalidate a cache' do
              expect(described_class).not_to receive(:matching).with(protected_branch.name, protected_refs: anything)

              project.touch

              described_class.protected?(project, protected_branch.name)
            end
          end

          context 'when other project protected branch is updated' do
            it 'does not invalidate the current project cache' do
              expect(described_class).not_to receive(:matching).with(protected_branch.name, protected_refs: anything)

              another_project = create(:project)
              ProtectedBranches::CreateService.new(another_project, another_project.owner, name: 'bar').execute

              described_class.protected?(project, protected_branch.name)
            end
          end

          it 'correctly uses the cached version' do
            expect(described_class).not_to receive(:matching)

            expect(described_class.protected?(project, protected_branch.name)).to eq(true)
          end
        end
      end
    end

    context 'new project' do
      using RSpec::Parameterized::TableSyntax

      let(:project) { create(:project) }

      context 'when the group has set their own default_branch_protection level' do
        where(:default_branch_protection_level, :result) do
          Gitlab::Access::PROTECTION_NONE          | false
          Gitlab::Access::PROTECTION_DEV_CAN_PUSH  | false
          Gitlab::Access::PROTECTION_DEV_CAN_MERGE | true
          Gitlab::Access::PROTECTION_FULL          | true
        end

        with_them do
          it 'protects the default branch based on the default branch protection setting of the group' do
            expect(project.namespace).to receive(:default_branch_protection).and_return(default_branch_protection_level)

            expect(described_class.protected?(project, 'master')).to eq(result)
          end
        end
      end

      context 'when the group has not set their own default_branch_protection level' do
        where(:default_branch_protection_level, :result) do
          Gitlab::Access::PROTECTION_NONE          | false
          Gitlab::Access::PROTECTION_DEV_CAN_PUSH  | false
          Gitlab::Access::PROTECTION_DEV_CAN_MERGE | true
          Gitlab::Access::PROTECTION_FULL          | true
        end

        with_them do
          before do
            stub_application_setting(default_branch_protection: default_branch_protection_level)
          end

          it 'protects the default branch based on the instance level default branch protection setting' do
            expect(described_class.protected?(project, 'master')).to eq(result)
          end
        end
      end
    end
  end

  describe "#allow_force_push?" do
    context "when the attr allow_force_push is true" do
      let(:subject_branch) { create(:protected_branch, allow_force_push: true, name: "foo") }

      it "returns true" do
        project = subject_branch.project

        expect(described_class.allow_force_push?(project, "foo")).to eq(true)
      end
    end

    context "when the attr allow_force_push is false" do
      let(:subject_branch) { create(:protected_branch, allow_force_push: false, name: "foo") }

      it "returns false" do
        project = subject_branch.project

        expect(described_class.allow_force_push?(project, "foo")).to eq(false)
      end
    end
  end

  describe '#any_protected?' do
    context 'existing project' do
      let(:project) { create(:project, :repository) }

      it 'returns true when any of the branch names match a protected branch via direct match' do
        create(:protected_branch, project: project, name: 'foo')

        expect(described_class.any_protected?(project, ['foo', 'production/some-branch'])).to eq(true)
      end

      it 'returns true when any of the branch matches a protected branch via wildcard match' do
        create(:protected_branch, project: project, name: 'production/*')

        expect(described_class.any_protected?(project, ['foo', 'production/some-branch'])).to eq(true)
      end

      it 'returns false when none of branches does not match a protected branch via direct match' do
        expect(described_class.any_protected?(project, ['foo'])).to eq(false)
      end

      it 'returns false when none of the branches does not match a protected branch via wildcard match' do
        create(:protected_branch, project: project, name: 'production/*')

        expect(described_class.any_protected?(project, ['staging/some-branch'])).to eq(false)
      end
    end
  end

  describe '.by_name' do
    let!(:protected_branch) { create(:protected_branch, name: 'master') }
    let!(:another_protected_branch) { create(:protected_branch, name: 'stable') }

    it 'returns protected branches with a matching name' do
      expect(described_class.by_name(protected_branch.name))
        .to eq([protected_branch])
    end

    it 'returns protected branches with a partially matching name' do
      expect(described_class.by_name(protected_branch.name[0..2]))
        .to eq([protected_branch])
    end

    it 'returns protected branches with a matching name regardless of the casing' do
      expect(described_class.by_name(protected_branch.name.upcase))
        .to eq([protected_branch])
    end

    it 'returns nothing when nothing matches' do
      expect(described_class.by_name('unknown')).to be_empty
    end

    it 'return nothing when query is blank' do
      expect(described_class.by_name('')).to be_empty
    end
  end

  describe '.get_ids_by_name' do
    let(:branch_name) { 'branch_name' }
    let!(:protected_branch) { create(:protected_branch, name: branch_name) }
    let(:branch_id) { protected_branch.id }

    it 'returns the id for each protected branch matching name' do
      expect(described_class.get_ids_by_name([branch_name]))
        .to match_array([branch_id])
    end
  end

  describe '.downcase_humanized_name' do
    it 'returns downcase humanized name' do
      expect(described_class.downcase_humanized_name).to eq 'protected branch'
    end
  end

  describe '.default_branch?' do
    before do
      allow(subject.project).to receive(:default_branch).and_return(branch)
    end

    context 'when the name matches the default branch' do
      let(:branch) { subject.name }

      it { is_expected.to be_default_branch }
    end

    context 'when the name does not match the default branch' do
      let(:branch) { "#{subject.name}qwerty" }

      it { is_expected.not_to be_default_branch }
    end

    context 'when a wildcard name matches the default branch' do
      let(:branch) { "#{subject.name}*" }

      it { is_expected.not_to be_default_branch }
    end
  end
end

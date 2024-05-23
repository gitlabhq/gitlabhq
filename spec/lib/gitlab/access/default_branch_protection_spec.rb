# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Access::DefaultBranchProtection, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  describe '#any?' do
    where(:setting, :result) do
      Gitlab::Access::BranchProtection.protection_none                    | false
      Gitlab::Access::BranchProtection.protection_partial                 | true
      Gitlab::Access::BranchProtection.protected_against_developer_pushes | true
      Gitlab::Access::BranchProtection.protected_fully                    | true
      Gitlab::Access::BranchProtection.protected_after_initial_push       | true
    end

    with_them do
      it { expect(described_class.new(setting).any?).to eq(result) }
    end
  end

  describe '#code_owner_approval_required?' do
    where(:setting, :result) do
      { code_owner_approval_required: true }   | true
      { code_owner_approval_required: false }  | false
      { code_owner_approval_required: nil }    | false
    end

    with_them do
      it { expect(described_class.new(setting).code_owner_approval_required?).to eq(result) }
    end
  end

  describe '#allow_force_push?' do
    where(:setting, :result) do
      { allow_force_push: true }   | true
      { allow_force_push: false }  | false
      { allow_force_push: nil }    | false
    end

    with_them do
      it { expect(described_class.new(setting).allow_force_push?).to eq(result) }
    end
  end

  describe '#no_one_can_push?' do
    it 'when push access level is NO_ACCESS' do
      expect(
        described_class.new({ allowed_to_push: [access_level: Gitlab::Access::NO_ACCESS] }).no_one_can_push?
      ).to be_truthy
    end

    it 'when push access level is not NO_ACCESS' do
      expect(
        described_class.new({ allowed_to_push: [access_level: Gitlab::Access::MAINTAINER] }).no_one_can_push?
      ).to be_falsey
    end
  end

  describe '#no_one_can_merge?' do
    it 'when merge access level is NO_ACCESS' do
      expect(
        described_class.new({ allowed_to_merge: [access_level: Gitlab::Access::NO_ACCESS] }).no_one_can_merge?
      ).to be_truthy
    end

    it 'when merge access level is not NO_ACCESS' do
      expect(
        described_class.new({ allowed_to_merge: [access_level: Gitlab::Access::MAINTAINER] }).no_one_can_merge?
      ).to be_falsey
    end
  end

  describe '#maintainer_can_push?' do
    it 'when push access level is MAINTAINER' do
      expect(
        described_class.new({ allowed_to_push: [access_level: Gitlab::Access::MAINTAINER] }).maintainer_can_push?
      ).to be_truthy
    end

    it 'when push access level is not MAINTAINER' do
      expect(
        described_class.new({ allowed_to_push: [access_level: Gitlab::Access::NO_ACCESS] }).maintainer_can_push?
      ).to be_falsey
    end
  end

  describe '#maintainer_can_merge?' do
    it 'when merge access level is MAINTAINER' do
      expect(
        described_class.new({ allowed_to_merge: [access_level: Gitlab::Access::MAINTAINER] }).maintainer_can_merge?
      ).to be_truthy
    end

    it 'when merge access level is not MAINTAINER' do
      expect(
        described_class.new({ allowed_to_merge: [access_level: Gitlab::Access::NO_ACCESS] }).maintainer_can_merge?
      ).to be_falsey
    end
  end

  describe '#developer_can_push?' do
    it 'when developer can push' do
      expect(
        described_class.new({ allowed_to_push: [access_level: Gitlab::Access::DEVELOPER] }).developer_can_push?
      ).to be_truthy
    end

    it 'when developer cannot push' do
      expect(
        described_class.new({ allowed_to_push: [access_level: Gitlab::Access::MAINTAINER] }).developer_can_push?
      ).to be_falsey
    end
  end

  describe '#developer_can_merge?' do
    it 'when developer can merge' do
      expect(
        described_class.new({ allowed_to_merge: [access_level: Gitlab::Access::DEVELOPER] }).developer_can_merge?
      ).to be_truthy
    end

    it 'when developer cannot merge' do
      expect(
        described_class.new({ allowed_to_merge: [access_level: Gitlab::Access::MAINTAINER] }).developer_can_merge?
      ).to be_falsey
    end
  end

  describe '#fully_protected?' do
    where(:setting, :result) do
      Gitlab::Access::BranchProtection.protection_none                    | false
      Gitlab::Access::BranchProtection.protection_partial                 | false
      Gitlab::Access::BranchProtection.protected_against_developer_pushes | false
      Gitlab::Access::BranchProtection.protected_fully                    | true
      Gitlab::Access::BranchProtection.protected_after_initial_push       | false
    end

    with_them do
      it { expect(described_class.new(setting).fully_protected?).to eq(result) }
    end
  end

  describe '#developer_can_initial_push?' do
    it 'when developer can initial push' do
      expect(described_class.new({ developer_can_initial_push: true }).developer_can_initial_push?).to be_truthy
    end

    it 'when developer cannot initial push' do
      expect(described_class.new({ developer_can_initial_push: false }).developer_can_initial_push?).to be_falsey
    end
  end
end

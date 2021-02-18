# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Access::BranchProtection do
  using RSpec::Parameterized::TableSyntax

  describe '#any?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE          | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH  | true
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE | true
      Gitlab::Access::PROTECTION_FULL          | true
    end

    with_them do
      it { expect(described_class.new(level).any?).to eq(result) }
    end
  end

  describe '#developer_can_push?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE          | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH  | true
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE | false
      Gitlab::Access::PROTECTION_FULL          | false
    end

    with_them do
      it do
        expect(described_class.new(level).developer_can_push?).to eq(result)
      end
    end
  end

  describe '#developer_can_merge?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE          | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH  | false
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE | true
      Gitlab::Access::PROTECTION_FULL          | false
    end

    with_them do
      it do
        expect(described_class.new(level).developer_can_merge?).to eq(result)
      end
    end
  end

  describe '#fully_protected?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE          | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH  | false
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE | false
      Gitlab::Access::PROTECTION_FULL          | true
    end

    with_them do
      it do
        expect(described_class.new(level).fully_protected?).to eq(result)
      end
    end
  end
end

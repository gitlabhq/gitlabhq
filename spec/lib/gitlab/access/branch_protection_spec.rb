# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Access::BranchProtection do
  using RSpec::Parameterized::TableSyntax

  describe '#any?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE                 | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | true
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | true
      Gitlab::Access::PROTECTION_FULL                 | true
      Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | true
    end

    with_them do
      it { expect(described_class.new(level).any?).to eq(result) }
    end
  end

  describe '#developer_can_push?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE                 | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | true
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | false
      Gitlab::Access::PROTECTION_FULL                 | false
      Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | false
    end

    with_them do
      it do
        expect(described_class.new(level).developer_can_push?).to eq(result)
      end
    end
  end

  describe '#developer_can_merge?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE                 | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | false
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | true
      Gitlab::Access::PROTECTION_FULL                 | false
      Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | false
    end

    with_them do
      it do
        expect(described_class.new(level).developer_can_merge?).to eq(result)
      end
    end
  end

  describe '#fully_protected?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE                 | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | false
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | false
      Gitlab::Access::PROTECTION_FULL                 | true
      Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | false
    end

    with_them do
      it do
        expect(described_class.new(level).fully_protected?).to eq(result)
      end
    end
  end

  describe '#developer_can_initial_push?' do
    where(:level, :result) do
      Gitlab::Access::PROTECTION_NONE                 | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | false
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | false
      Gitlab::Access::PROTECTION_FULL                 | false
      Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | true
    end

    with_them do
      it do
        expect(described_class.new(level).developer_can_initial_push?).to eq(result)
      end
    end
  end

  describe '#to_hash' do
    context 'for allow_force_push' do
      subject { described_class.new(level).to_hash[:allow_force_push] }

      where(:level, :result) do
        Gitlab::Access::PROTECTION_NONE                 | true
        Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | false
        Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | false
        Gitlab::Access::PROTECTION_FULL                 | false
        Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | false
      end

      with_them { it { is_expected.to eq(result) } }
    end

    context 'for allowed_to_push' do
      subject { described_class.new(level).to_hash[:allowed_to_push] }

      where(:level, :result) do
        Gitlab::Access::PROTECTION_NONE                 | [{ 'access_level' => Gitlab::Access::DEVELOPER }]
        Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | [{ 'access_level' => Gitlab::Access::DEVELOPER }]
        Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | [{ 'access_level' => Gitlab::Access::MAINTAINER }]
        Gitlab::Access::PROTECTION_FULL                 | [{ 'access_level' => Gitlab::Access::MAINTAINER }]
        Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | [{ 'access_level' => Gitlab::Access::MAINTAINER }]
      end

      with_them { it { is_expected.to eq(result) } }
    end

    context 'for allowed_to_merge' do
      subject { described_class.new(level).to_hash[:allowed_to_merge] }

      where(:level, :result) do
        Gitlab::Access::PROTECTION_NONE                 | [{ 'access_level' => Gitlab::Access::DEVELOPER }]
        Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | [{ 'access_level' => Gitlab::Access::MAINTAINER }]
        Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | [{ 'access_level' => Gitlab::Access::DEVELOPER }]
        Gitlab::Access::PROTECTION_FULL                 | [{ 'access_level' => Gitlab::Access::MAINTAINER }]
        Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | [{ 'access_level' => Gitlab::Access::MAINTAINER }]
      end

      with_them { it { is_expected.to eq(result) } }
    end

    context 'for developer_can_initial_push' do
      subject { described_class.new(level).to_hash[:developer_can_initial_push] }

      where(:level, :result) do
        Gitlab::Access::PROTECTION_NONE                 | false
        Gitlab::Access::PROTECTION_DEV_CAN_PUSH         | false
        Gitlab::Access::PROTECTION_DEV_CAN_MERGE        | false
        Gitlab::Access::PROTECTION_FULL                 | false
        Gitlab::Access::PROTECTION_DEV_CAN_INITIAL_PUSH | true
      end

      with_them { it { is_expected.to eq(result) } }
    end
  end
end

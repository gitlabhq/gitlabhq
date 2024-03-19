# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Access::DefaultBranchProtection, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }

  describe '#any?' do
    where(:setting, :result) do
      Gitlab::Access::BranchProtection.protection_none                    | false
      Gitlab::Access::BranchProtection.protection_partial                 | true
      Gitlab::Access::BranchProtection.protected_against_developer_pushes | true
      Gitlab::Access::BranchProtection.protected_fully                    | true
      Gitlab::Access::BranchProtection.protected_after_initial_push       | true
    end

    with_them do
      before do
        allow(project.namespace).to receive(:default_branch_protection_settings).and_return(setting)
      end

      it { expect(described_class.new(project).any?).to eq(result) }
    end
  end

  describe '#developer_can_push?' do
    context 'when developer can push' do
      before do
        allow(project.namespace).to receive(:default_branch_protection_settings)
                                      .and_return({ allowed_to_push: [access_level: Gitlab::Access::DEVELOPER] })
      end

      it { expect(described_class.new(project).developer_can_push?).to be_truthy }
    end

    context 'when developer cannot push' do
      before do
        allow(project.namespace).to receive(:default_branch_protection_settings)
                                      .and_return({ allowed_to_push: [access_level: Gitlab::Access::MAINTAINER] })
      end

      it { expect(described_class.new(project).developer_can_push?).to be_falsey }
    end
  end

  describe '#developer_can_merge?' do
    context 'when developer can merge' do
      before do
        allow(project.namespace).to receive(:default_branch_protection_settings)
                                      .and_return({ allowed_to_merge: [access_level: Gitlab::Access::DEVELOPER] })
      end

      it { expect(described_class.new(project).developer_can_merge?).to be_truthy }
    end

    context 'when developer cannot merge' do
      before do
        allow(project.namespace).to receive(:default_branch_protection_settings)
                                      .and_return({ allowed_to_merge: [access_level: Gitlab::Access::MAINTAINER] })
      end

      it { expect(described_class.new(project).developer_can_merge?).to be_falsey }
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
      before do
        allow(project.namespace).to receive(:default_branch_protection_settings)
                                      .and_return(setting)
      end

      it { expect(described_class.new(project).fully_protected?).to eq(result) }
    end
  end

  describe '#developer_can_initial_push?' do
    context 'when developer can initial push' do
      before do
        allow(project.namespace).to receive(:default_branch_protection_settings)
                                      .and_return({ developer_can_initial_push: true })
      end

      it { expect(described_class.new(project).developer_can_initial_push?).to be_truthy }
    end

    context 'when developer cannot initial push' do
      before do
        allow(project.namespace).to receive(:default_branch_protection_settings)
                                      .and_return({ developer_can_initial_push: false })
      end

      it { expect(described_class.new(project).developer_can_initial_push?).to be_falsey }
    end
  end
end

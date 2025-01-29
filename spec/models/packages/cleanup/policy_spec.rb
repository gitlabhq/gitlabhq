# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cleanup::Policy, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    it do
      is_expected
        .to validate_inclusion_of(:keep_n_duplicated_package_files)
              .in_array(described_class::KEEP_N_DUPLICATED_PACKAGE_FILES_VALUES)
              .with_message('is invalid')
    end
  end

  describe '.active' do
    let_it_be(:active_policy) { create(:packages_cleanup_policy) }
    let_it_be(:inactive_policy) { create(:packages_cleanup_policy, keep_n_duplicated_package_files: 'all') }

    subject { described_class.active }

    it { is_expected.to contain_exactly(active_policy) }
  end

  describe '.with_packages' do
    let_it_be(:policy_with_packages) { create(:packages_cleanup_policy) }
    let_it_be(:policy_without_packages) { create(:packages_cleanup_policy) }
    let_it_be(:package) { create(:generic_package, project: policy_with_packages.project) }

    subject { described_class.with_packages }

    it { is_expected.to contain_exactly(policy_with_packages) }
  end

  describe '.runnable' do
    let_it_be(:runnable_policy_with_packages) { create(:packages_cleanup_policy, :runnable) }
    let_it_be(:runnable_policy_without_packages) { create(:packages_cleanup_policy, :runnable) }
    let_it_be(:non_runnable_policy_with_packages) { create(:packages_cleanup_policy) }
    let_it_be(:non_runnable_policy_without_packages) { create(:packages_cleanup_policy) }

    let_it_be(:package1) { create(:generic_package, project: runnable_policy_with_packages.project) }
    let_it_be(:package2) { create(:generic_package, project: non_runnable_policy_with_packages.project) }

    subject { described_class.runnable }

    it { is_expected.to contain_exactly(runnable_policy_with_packages) }
  end

  describe '#keep_n_duplicated_package_files_disabled?' do
    subject { policy.keep_n_duplicated_package_files_disabled? }

    %w[all 1].each do |value|
      context "with value set to #{value}" do
        let(:policy) { build(:packages_cleanup_policy, keep_n_duplicated_package_files: value) }

        it { is_expected.to eq(value == 'all') }
      end
    end
  end
end

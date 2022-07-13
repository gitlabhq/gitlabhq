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

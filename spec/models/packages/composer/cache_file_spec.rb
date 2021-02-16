# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Composer::CacheFile, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
  end

  describe 'scopes' do
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group) }
    let_it_be(:cache_file1) { create(:composer_cache_file, file_sha256: '123456', group: group1) }
    let_it_be(:cache_file2) { create(:composer_cache_file, delete_at: 2.days.from_now, file_sha256: '456778', group: group2) }

    describe '.with_namespace' do
      subject { described_class.with_namespace(group1) }

      it { is_expected.to eq [cache_file1] }
    end

    describe '.with_sha' do
      subject { described_class.with_sha('123456') }

      it { is_expected.to eq [cache_file1] }
    end
  end
end

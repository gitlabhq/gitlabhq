# frozen_string_literal: true

require 'spec_helper'

describe PoolRepository do
  describe 'associations' do
    it { is_expected.to belong_to(:shard) }
    it { is_expected.to have_one(:source_project) }
    it { is_expected.to have_many(:member_projects) }
  end

  describe 'validations' do
    let!(:pool_repository) { create(:pool_repository) }

    it { is_expected.to validate_presence_of(:shard) }
    it { is_expected.to validate_presence_of(:source_project) }
  end

  describe '#disk_path' do
    it 'sets the hashed disk_path' do
      pool = create(:pool_repository)

      expect(pool.disk_path).to match(%r{\A@pools/\h{2}/\h{2}/\h{64}})
    end
  end
end

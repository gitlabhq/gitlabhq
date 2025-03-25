# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PopulatesShardingKey, feature_category: :database do
  let(:described_class) do
    Class.new(ApplicationRecord) do
      include PopulatesShardingKey

      self.table_name = 'users'

      attr_accessor :sharding_source
    end
  end

  let(:sharding_key_value) { 109 }

  describe '.populate_sharding_key' do
    context 'when only source is defined' do
      before do
        described_class.populate_sharding_key :role, source: :sharding_source
      end

      subject { described_class.new(sharding_source: double(role: sharding_key_value)) } # rubocop:disable RSpec/VerifiedDoubles -- the source can be anything so can't set verified double.

      it { is_expected.to populate_sharding_key(:role).from(:sharding_source) }
    end

    context 'with source and field defined' do
      before do
        described_class.populate_sharding_key :role, source: :sharding_source, field: :sharding_field
      end

      subject { described_class.new(sharding_source: double(sharding_field: sharding_key_value)) } # rubocop:disable RSpec/VerifiedDoubles -- the source can be anything so can't set verified double.

      it { is_expected.to populate_sharding_key(:role).from(:sharding_source, :sharding_field) }
    end

    context 'with block passed' do
      before do
        described_class.populate_sharding_key(:role) { sharding_source }
      end

      subject { described_class.new(sharding_source: sharding_key_value) }

      it { is_expected.to populate_sharding_key(:role).with(sharding_key_value) }
    end

    context 'with block passed as symbol' do
      before do
        described_class.populate_sharding_key :role, &:sharding_source
      end

      subject { described_class.new(sharding_source: sharding_key_value) }

      it { is_expected.to populate_sharding_key(:role).with(sharding_key_value) }
    end
  end
end

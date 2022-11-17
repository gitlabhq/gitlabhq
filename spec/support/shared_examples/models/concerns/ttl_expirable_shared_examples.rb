# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'ttl_expirable' do
  let_it_be(:class_symbol) { described_class.model_name.param_key.to_sym }

  it_behaves_like 'having unique enum values'

  describe 'default values', :freeze_time do
    it { expect(described_class.new.read_at).to be_like_time(Time.zone.now) }
    it { expect(described_class.new(read_at: 1.day.ago).read_at).to be_like_time(1.day.ago) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
  end

  describe '.read_before' do
    # rubocop:disable Rails/SaveBang
    let_it_be_with_reload(:item1) { create(class_symbol) }
    let_it_be(:item2) { create(class_symbol) }
    # rubocop:enable Rails/SaveBang

    before do
      item1.update_column(:read_at, 1.month.ago)
    end

    it 'returns items with created at older than the supplied number of days' do
      expect(described_class.read_before(10)).to contain_exactly(item1)
    end
  end

  describe '.active' do
    # rubocop:disable Rails/SaveBang
    let_it_be(:item1) { create(class_symbol) }
    let_it_be(:item2) { create(class_symbol, :pending_destruction) }
    let_it_be(:item3) { create(class_symbol, status: :error) }
    # rubocop:enable Rails/SaveBang

    it 'returns only active items' do
      expect(described_class.active).to contain_exactly(item1)
    end
  end

  describe '#read!', :freeze_time do
    let_it_be(:old_read_at) { 1.day.ago }
    let_it_be(:item1) { create(class_symbol, read_at: old_read_at) }

    it 'updates read_at' do
      expect { item1.read! }.to change { item1.reload.read_at }
    end
  end
end

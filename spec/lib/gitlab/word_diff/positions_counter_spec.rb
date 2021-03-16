# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WordDiff::PositionsCounter do
  subject(:counter) { described_class.new }

  describe 'Initial state' do
    it 'starts with predefined values' do
      expect(counter.pos_old).to eq(1)
      expect(counter.pos_new).to eq(1)
      expect(counter.line_obj_index).to eq(0)
    end
  end

  describe '#increase_pos_num' do
    it 'increases old and new positions' do
      expect { counter.increase_pos_num }.to change { counter.pos_old }.from(1).to(2)
                                               .and change { counter.pos_new }.from(1).to(2)
    end
  end

  describe '#increase_obj_index' do
    it 'increases object index' do
      expect { counter.increase_obj_index }.to change { counter.line_obj_index }.from(0).to(1)
    end
  end

  describe '#set_pos_num' do
    it 'sets old and new positions' do
      expect { counter.set_pos_num(old: 10, new: 12) }.to change { counter.pos_old }.from(1).to(10)
                                                            .and change { counter.pos_new }.from(1).to(12)
    end
  end
end

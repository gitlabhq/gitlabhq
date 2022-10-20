# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdInOrdered do
  describe 'Issue' do
    describe '.id_in_ordered' do
      it 'returns issues matching the ids in the same order as the ids' do
        issue1 = create(:issue)
        issue2 = create(:issue)
        issue3 = create(:issue)
        issue4 = create(:issue)
        issue5 = create(:issue)

        expect(Issue.id_in_ordered([issue3.id, issue1.id, issue4.id, issue5.id, issue2.id])).to eq(
          [
            issue3, issue1, issue4, issue5, issue2
          ])
      end

      context 'when the ids are not an array of integers' do
        it 'raises ArgumentError' do
          expect { Issue.id_in_ordered([1, 'no SQL injection']) }.to raise_error(ArgumentError, "ids must be an array of integers")
        end
      end

      context 'when an empty array is given' do
        it 'does not raise error' do
          expect(Issue.id_in_ordered([]).to_a).to be_empty
        end
      end
    end
  end
end

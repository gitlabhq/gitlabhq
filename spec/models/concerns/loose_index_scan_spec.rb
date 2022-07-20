# frozen_string_literal: true
# frozen_string_literal

require 'spec_helper'

RSpec.describe LooseIndexScan, type: :model do
  let(:issue_model) do
    Class.new(ApplicationRecord) do
      include LooseIndexScan

      self.table_name = 'issues'
    end
  end

  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:user_3) { create(:user) }

  let_it_be(:issue_1) { create(:issue, author: user_2) }
  let_it_be(:issue_2) { create(:issue, author: user_1) }
  let_it_be(:issue_3) { create(:issue, author: user_1) }
  let_it_be(:issue_4) { create(:issue, author: user_2) }
  let_it_be(:issue_5) { create(:issue, author: user_3) }

  context 'loading distinct author_ids' do
    subject(:author_ids) { issue_model.loose_index_scan(column: :author_id, order: order).pluck(:author_id) }

    shared_examples 'assert distinct values example' do
      it 'loads the distinct values in the correct order' do
        expect(author_ids).to eq(expected_order)
      end
    end

    context 'when using ascending order' do
      let(:order) { :asc }
      let(:expected_order) { [user_1.id, user_2.id, user_3.id] }

      it_behaves_like 'assert distinct values example'

      context 'when null values are present' do
        before do
          issue_1.author_id = nil
          issue_1.save!(validate: false)
        end

        it_behaves_like 'assert distinct values example'
      end

      context 'when using descending order' do
        let(:order) { :desc }
        let(:expected_order) { [user_3.id, user_2.id, user_1.id] }

        it_behaves_like 'assert distinct values example'
      end
    end
  end
end

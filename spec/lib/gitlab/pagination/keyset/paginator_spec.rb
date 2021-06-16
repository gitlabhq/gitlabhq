# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::Paginator do
  let_it_be(:project_1) { create(:project, created_at: 10.weeks.ago) }
  let_it_be(:project_2) { create(:project, created_at: 2.weeks.ago) }
  let_it_be(:project_3) { create(:project, created_at: 3.weeks.ago) }
  let_it_be(:project_4) { create(:project, created_at: 5.weeks.ago) }
  let_it_be(:project_5) { create(:project, created_at: 2.weeks.ago) }

  describe 'pagination' do
    let(:per_page) { 10 }
    let(:cursor) { nil }
    let(:scope) { Project.order(created_at: :asc, id: :asc) }
    let(:expected_order) { [project_1, project_4, project_3, project_2, project_5] }

    subject(:paginator) { scope.keyset_paginate(cursor: cursor, per_page: per_page) }

    context 'when per_page is greater than the record count' do
      it { expect(paginator.records).to eq(expected_order) }
      it { is_expected.not_to have_next_page }
      it { is_expected.not_to have_previous_page }

      it 'has no next and previous cursor values' do
        expect(paginator.cursor_for_next_page).to be_nil
        expect(paginator.cursor_for_previous_page).to be_nil
      end
    end

    context 'when 0 records are returned' do
      let(:scope) { Project.where(id: non_existing_record_id).order(created_at: :asc, id: :asc) }

      it { expect(paginator.records).to be_empty }
      it { is_expected.not_to have_next_page }
      it { is_expected.not_to have_previous_page }
    end

    context 'when page size is smaller than the record count' do
      let(:per_page) { 2 }

      it { expect(paginator.records).to eq(expected_order.first(2)) }
      it { is_expected.to have_next_page }
      it { is_expected.not_to have_previous_page }

      it 'has next page cursor' do
        expect(paginator.cursor_for_next_page).not_to be_nil
      end

      it 'does not have previous page cursor' do
        expect(paginator.cursor_for_previous_page).to be_nil
      end

      context 'when on the second page' do
        let(:cursor) { scope.keyset_paginate(per_page: per_page).cursor_for_next_page }

        it { expect(paginator.records).to eq(expected_order[2...4]) }
        it { is_expected.to have_next_page }
        it { is_expected.to have_previous_page }

        context 'and then going back to the first page' do
          let(:previous_page_cursor) { scope.keyset_paginate(cursor: cursor, per_page: per_page).cursor_for_previous_page }

          subject(:paginator) { scope.keyset_paginate(cursor: previous_page_cursor, per_page: per_page) }

          it { expect(paginator.records).to eq(expected_order.first(2)) }
          it { is_expected.to have_next_page }
          it { is_expected.not_to have_previous_page }
        end
      end

      context 'when jumping to the last page' do
        let(:cursor) { scope.keyset_paginate(per_page: per_page).cursor_for_last_page }

        it { expect(paginator.records).to eq(expected_order.last(2)) }
        it { is_expected.not_to have_next_page }
        it { is_expected.to have_previous_page }

        context 'when paginating backwards' do
          let(:previous_page_cursor) { scope.keyset_paginate(cursor: cursor, per_page: per_page).cursor_for_previous_page }

          subject(:paginator) { scope.keyset_paginate(cursor: previous_page_cursor, per_page: per_page) }

          it { expect(paginator.records).to eq(expected_order[-4...-2]) }
          it { is_expected.to have_next_page }
          it { is_expected.to have_previous_page }
        end

        context 'when jumping to the first page' do
          let(:first_page_cursor) { scope.keyset_paginate(cursor: cursor, per_page: per_page).cursor_for_first_page }

          subject(:paginator) { scope.keyset_paginate(cursor: first_page_cursor, per_page: per_page) }

          it { expect(paginator.records).to eq(expected_order.first(2)) }
          it { is_expected.to have_next_page }
          it { is_expected.not_to have_previous_page }
        end
      end
    end

    describe 'default keyset direction parameter' do
      let(:cursor_converter_class) { Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter }
      let(:per_page) { 2 }

      it 'exposes the direction parameter in the cursor' do
        cursor = paginator.cursor_for_next_page

        expect(cursor_converter_class.parse(cursor)[:_kd]).to eq(described_class::FORWARD_DIRECTION)
      end
    end
  end

  context 'when unsupported order is given' do
    it 'raises error' do
      scope = Project.order(path: :asc, name: :asc, id: :desc) # Cannot build 3 column order automatically

      expect { scope.keyset_paginate }.to raise_error(/does not support keyset pagination/)
    end
  end

  context 'when use_union_optimization option is true and ordering by two columns' do
    let(:scope) { Project.order(name: :asc, id: :desc) }

    it 'uses UNION queries' do
      paginator_first_page = scope.keyset_paginate(
        per_page: 2,
        keyset_order_options: { use_union_optimization: true }
      )

      paginator_second_page = scope.keyset_paginate(
        per_page: 2,
        cursor: paginator_first_page.cursor_for_next_page,
        keyset_order_options: { use_union_optimization: true }
      )

      expect_next_instances_of(Gitlab::SQL::Union, 1) do |instance|
        expect(instance.to_sql).to include(paginator_first_page.records.last.name)
      end

      paginator_second_page.records.to_a
    end
  end
end

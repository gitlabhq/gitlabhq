# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Offset::PaginationWithIndexOnlyScan, feature_category: :database do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue1) { create(:issue, project: project, closed_at: 3.days.ago) }
  let_it_be(:issue2) { create(:issue, project: project, closed_at: 2.days.ago) }
  let_it_be(:issue3) { create(:issue, project: project, closed_at: 5.days.ago) }
  let_it_be(:issue4) { create(:issue, project: project, closed_at: nil) }

  let_it_be(:outside_issue) { create(:issue, project: project) }

  let!(:offset_paginated_result) { scope.page(page).per(per) }

  let(:optimization) { described_class.new(scope: scope, page: page, per_page: per) }
  let(:per) { 2 }
  let(:page) { 1 }

  subject(:result) { optimization.paginate_with_kaminari }

  RSpec::Matchers.define :match_pagination_results do |expected|
    match do |actual|
      expect(expected.to_a).to eq(actual.to_a)
      expect(expected.offset_value).to eq(actual.offset_value)
      expect(expected.limit_value).to eq(actual.limit_value)
      expect(expected.select_values).to eq(actual.select_values)
      expect(expected.includes_values).to eq(actual.includes_values)
      expect(expected.preload_values).to eq(actual.preload_values)
      expect(expected.eager_load_values).to eq(actual.eager_load_values)
    end
  end

  context 'when sorting by id' do
    let!(:scope) { Issue.where(project: project).order(id: :desc) }

    it { is_expected.to match_pagination_results(offset_paginated_result) }

    it 'calls the optimized code path' do
      expect(optimization).to receive(:build_module_for_load).and_call_original

      result
    end

    context 'when requesting the 2nd page' do
      let(:page) { 2 }

      it { is_expected.to match_pagination_results(offset_paginated_result) }
    end

    context 'when selecting specific columns' do
      let!(:scope) { Issue.where(project: project).order(id: :desc).select(:id, :title) }

      it 'only loads the selected columns' do
        expect(result).to match_pagination_results(offset_paginated_result)

        expect(result.first).not_to have_attribute(:description)
      end
    end
  end

  context 'when sorting by closed at' do
    let!(:scope) { Issue.where(project: project).order(:closed_at, :id) }

    it { is_expected.to match_pagination_results(offset_paginated_result) }

    context 'when one of the closed_at value is null' do
      let(:page) { 2 }

      it { is_expected.to match_pagination_results(offset_paginated_result) }
    end

    context 'when no records are returned' do
      let(:page) { 15 }

      it { is_expected.to match_pagination_results(offset_paginated_result) }
    end
  end

  context 'when sorting by an SQL expression' do
    context 'when the SQL expression is not keyset-pagination aware' do
      let!(:scope) { Issue.where(project: project).order(Arel.sql('id + 1'), :id) }

      it 'does not apply the optimization' do
        expect(optimization).not_to receive(:build_module_for_load)

        result
      end
    end

    context 'when the SQL expression supports keyset-pagination' do
      let(:order) do
        Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id_plus_one',
            order_expression: Arel.sql('id + 1').asc
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'id',
            order_expression: Issue.arel_table[:id].asc
          )
        ])
      end

      let!(:scope) { Issue.where(project: project).order(order) }

      it { is_expected.to match_pagination_results(offset_paginated_result) }

      it 'calls the optimized code path' do
        expect(optimization).to receive(:build_module_for_load).and_call_original

        result
      end
    end
  end

  context 'when the scope is not sorted' do
    let!(:scope) { Issue.where(project: project) }

    it 'does not apply the optimization' do
      expect(optimization).not_to receive(:build_module_for_load)

      result
    end
  end

  context 'when STI scope is used' do
    let!(:build1) { create(:ci_build) }
    let!(:build2) { create(:ci_build) }

    let!(:scope) { Ci::Build.where({}).order(:id) }

    let(:per) { 1 }
    let(:page) { 2 }

    it { is_expected.to match_pagination_results(offset_paginated_result) }

    it 'calls the optimized code path' do
      expect(optimization).to receive(:build_module_for_load).and_call_original

      result
    end
  end
end

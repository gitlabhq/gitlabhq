# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EachBatch do
  let(:model) do
    Class.new(ActiveRecord::Base) do
      include EachBatch

      self.table_name = 'users'

      scope :never_signed_in, -> { where(sign_in_count: 0) }
    end
  end

  describe '.each_batch' do
    before do
      create_list(:user, 5, updated_at: 1.day.ago)
    end

    shared_examples 'each_batch handling' do |kwargs|
      it 'yields an ActiveRecord::Relation when a block is given' do
        model.each_batch(**kwargs) do |relation|
          expect(relation).to be_a_kind_of(ActiveRecord::Relation)
        end
      end

      it 'yields a batch index as the second argument' do
        model.each_batch(**kwargs) do |_, index|
          expect(index).to eq(1)
        end
      end

      it 'accepts a custom batch size' do
        amount = 0

        model.each_batch(**kwargs.merge({ of: 1 })) { amount += 1 }

        expect(amount).to eq(5)
      end

      it 'does not include ORDER BYs in the yielded relations' do
        model.each_batch do |relation|
          expect(relation.to_sql).not_to include('ORDER BY')
        end
      end

      it 'allows updating of the yielded relations' do
        time = Time.current

        model.each_batch do |relation|
          relation.update_all(updated_at: time)
        end

        expect(model.where(updated_at: time).count).to eq(5)
      end
    end

    it_behaves_like 'each_batch handling', {}
    it_behaves_like 'each_batch handling', { order_hint: :updated_at }

    it 'orders ascending by default' do
      ids = []

      model.each_batch(of: 1) { |rel| ids.concat(rel.ids) }

      expect(ids).to eq(ids.sort)
    end

    it 'accepts descending order' do
      ids = []

      model.each_batch(of: 1, order: :desc) { |rel| ids.concat(rel.ids) }

      expect(ids).to eq(ids.sort.reverse)
    end

    it 'does not reset order if requested' do
      model.update_all(color_scheme_id: 2)
      create(:user, color_scheme_id: 1)
      batch = []

      model.order(:color_scheme_id).each_batch(reset_order: false) { |rel| batch = rel.to_a }

      expected = batch.sort_by { |u| [u.color_scheme_id, u.id] }.map(&:id)
      actual = batch.map(&:id)

      expect(actual).to eq(expected)
    end

    shared_examples 'preloaded batch' do |method|
      it 'respects preloading without N+1 queries' do
        one, two = User.first(2)

        create(:key, user: one)

        scope = User.send(method, :keys)

        control = ActiveRecord::QueryRecorder.new { scope.each_batch(of: 5) { |batch| batch.each(&:keys) } }

        create(:key, user: one)
        create(:key, user: two)

        expect { scope.each_batch(of: 5) { |batch| batch.each(&:keys) } }.not_to exceed_query_limit(control)
      end
    end

    it_behaves_like 'preloaded batch', :preload
    it_behaves_like 'preloaded batch', :includes

    describe 'current scope' do
      let(:entry) { create(:user, sign_in_count: 1) }
      let(:ids_with_new_relation) { model.where(id: entry.id).pluck(:id) }

      it 'does not leak current scope to block being executed' do
        model.never_signed_in.each_batch(of: 5) do |relation|
          expect(ids_with_new_relation).to include(entry.id)
        end
      end
    end
  end

  describe '.distinct_each_batch' do
    let_it_be(:users) { create_list(:user, 5, sign_in_count: 0) }

    let(:params) { {} }

    subject(:values) do
      values = []

      model.distinct_each_batch(**params) { |rel| values.concat(rel.pluck(params[:column])) }
      values
    end

    context 'when iterating over a unique column' do
      context 'when using ascending order' do
        let(:expected_values) { users.pluck(:id).sort }
        let(:params) { { column: :id, of: 1, order: :asc } }

        it { is_expected.to eq(expected_values) }

        context 'when using larger batch size' do
          before do
            params[:of] = 3
          end

          it { is_expected.to eq(expected_values) }
        end

        context 'when using larger batch size than the result size' do
          before do
            params[:of] = 100
          end

          it { is_expected.to eq(expected_values) }
        end
      end

      context 'when using descending order' do
        let(:expected_values) { users.pluck(:id).sort.reverse }
        let(:params) { { column: :id, of: 1, order: :desc } }

        it { is_expected.to eq(expected_values) }

        context 'when using larger batch size' do
          before do
            params[:of] = 3
          end

          it { is_expected.to eq(expected_values) }
        end
      end
    end

    context 'when iterating over a non-unique column' do
      let(:params) { { column: :sign_in_count, of: 2, order: :asc } }

      context 'when only one value is present' do
        it { is_expected.to eq([0]) }
      end

      context 'when duplicated values present' do
        let(:expected_values) { [2, 5] }

        before do
          users[0].reload.update!(sign_in_count: 5)
          users[1].reload.update!(sign_in_count: 2)
          users[2].reload.update!(sign_in_count: 5)
          users[3].reload.update!(sign_in_count: 2)
          users[4].reload.update!(sign_in_count: 5)
        end

        it { is_expected.to eq(expected_values) }

        context 'when using descending order' do
          let(:expected_values) { [5, 2] }

          before do
            params[:order] = :desc
          end

          it { is_expected.to eq(expected_values) }
        end
      end
    end
  end

  describe '.each_batch_count' do
    let_it_be(:users) { create_list(:user, 5, updated_at: 1.day.ago) }

    it 'counts the records' do
      count, last_value = User.each_batch_count

      expect(count).to eq(5)
      expect(last_value).to eq(nil)
    end

    context 'when using a different column' do
      it 'returns correct count' do
        count, _ = User.each_batch_count(column: :email, of: 2)

        expect(count).to eq(5)
      end
    end

    context 'when stopping and resuming the counting' do
      it 'returns the correct count' do
        count, last_value = User.each_batch_count(of: 1) do |current_count, _current_value|
          current_count == 3 # stop when count reaches 3
        end

        expect(count).to eq(3)

        final_count, _ = User.each_batch_count(of: 1, last_value: last_value, last_count: count)
        expect(final_count).to eq(5)
      end
    end
  end
end

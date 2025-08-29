# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/FeatureCategory -- No feature category
RSpec.describe Gitlab::Pagination::GraphqlKeysetPagination do
  # rubocop: enable RSpec/FeatureCategory
  let(:test_class) do
    Class.new do
      include Gitlab::Pagination::GraphqlKeysetPagination

      attr_reader :params

      def initialize(params = {})
        @params = params
      end

      public :paginate_with_keyset
    end
  end

  let(:instance) { test_class.new(params) }
  let(:params) { {} }

  let_it_be(:project1) { create(:project, name: 'Alpha') }
  let_it_be(:project2) { create(:project, name: 'Beta') }
  let_it_be(:project3) { create(:project, name: 'Gamma') }
  let_it_be(:project4) { create(:project, name: 'Delta') }
  let_it_be(:project5) { create(:project, name: 'Epsilon') }

  describe '#paginate_with_keyset' do
    let(:scope) { Project.where(id: [project1.id, project2.id, project3.id, project4.id, project5.id]).order(id: :asc) }

    context 'with first parameter' do
      let(:params) { { first: 2 } }

      it 'returns first N records' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records].map(&:id)).to match_array([project1.id, project2.id])
        expect(result[:page_info][:has_next_page]).to be true
        expect(result[:page_info][:has_previous_page]).to be false
      end
    end

    context 'with last parameter' do
      let(:params) { { last: 2 } }

      it 'returns last N records' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records].map(&:id)).to match_array([project4.id, project5.id])
        expect(result[:page_info][:has_next_page]).to be false
        expect(result[:page_info][:has_previous_page]).to be true
      end
    end

    context 'with after cursor' do
      let(:cursor) { Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.dump(id: project2.id) }
      let(:params) { { first: 2, after: cursor } }

      it 'returns records after cursor' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records].map(&:id)).to match_array([project3.id, project4.id])
        expect(result[:page_info][:has_next_page]).to be true
        expect(result[:page_info][:has_previous_page]).to be true
      end
    end

    context 'with before cursor' do
      let(:cursor) { Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.dump(id: project4.id) }
      let(:params) { { first: 2, before: cursor } }

      it 'returns records before cursor' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records].map(&:id)).to match_array([project1.id, project2.id])
        expect(result[:page_info][:has_next_page]).to be true
        expect(result[:page_info][:has_previous_page]).to be false
      end
    end

    context 'with both after and before cursors' do
      let(:after_cursor) { Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.dump(id: project1.id) }
      let(:before_cursor) { Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.dump(id: project5.id) }
      let(:params) { { first: 2, after: after_cursor, before: before_cursor } }

      it 'returns records between cursors' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records].map(&:id)).to match_array([project2.id, project3.id])
        expect(result[:page_info][:has_next_page]).to be true
        expect(result[:page_info][:has_previous_page]).to be true
      end
    end

    context 'with last and before cursor' do
      let(:cursor) { Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.dump(id: project4.id) }
      let(:params) { { last: 2, before: cursor } }

      it 'returns last N records before cursor' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records].map(&:id)).to match_array([project2.id, project3.id])
        expect(result[:page_info][:has_next_page]).to be true
        expect(result[:page_info][:has_previous_page]).to be true
      end
    end

    context 'with last and after cursor' do
      let(:cursor) { Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.dump(id: project2.id) }
      let(:params) { { last: 2, after: cursor } }

      it 'returns last N records after cursor' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records].map(&:id)).to match_array([project4.id, project5.id])
        expect(result[:page_info][:has_next_page]).to be false
        expect(result[:page_info][:has_previous_page]).to be true
      end
    end

    context 'with empty result set' do
      let(:scope) { Project.none }
      let(:params) { { first: 10 } }

      it 'returns empty page info' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records]).to be_empty
        expect(result[:page_info]).to eq({
          has_next_page: false,
          has_previous_page: false,
          start_cursor: nil,
          end_cursor: nil
        })
      end
    end

    context 'with complex ordering' do
      let(:scope) { Project.where(id: [project1.id, project2.id, project3.id]).order(name: :asc, id: :asc) }
      let(:params) { { first: 2 } }

      it 'handles multi-column ordering' do
        result = instance.paginate_with_keyset(scope, params)

        expect(result[:records].map(&:name)).to match_array([project1.name, project2.name])
        expect(result[:page_info][:has_next_page]).to be true

        cursor = result[:page_info][:end_cursor]
        decoded = Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.parse(cursor)
        expect(decoded.keys).to match_array(%w[name id])
      end
    end

    context 'with unsupported ordering' do
      let(:scope) { Project.joins(:namespace).order('namespaces.name') }
      let(:params) { { first: 2 } }

      it 'raises UnsupportedScopeOrder error' do
        expect { instance.paginate_with_keyset(scope, params) }
          .to raise_error(Gitlab::Pagination::Keyset::UnsupportedScopeOrder)
      end
    end
  end

  describe '#calculate_has_next_page' do
    context 'when using first' do
      it 'returns true when has_more is true' do
        result = instance.send(:calculate_has_next_page, true, { first: 10 })
        expect(result).to be true
      end

      it 'returns false when has_more is false' do
        result = instance.send(:calculate_has_next_page, false, { first: 10 })
        expect(result).to be false
      end
    end

    context 'when using last' do
      it 'returns true when before is present' do
        result = instance.send(:calculate_has_next_page, false, { last: 10, before: 'cursor' })
        expect(result).to be true
      end

      it 'returns false when before is not present' do
        result = instance.send(:calculate_has_next_page, false, { last: 10 })
        expect(result).to be false
      end
    end
  end

  describe '#calculate_has_previous_page' do
    context 'when using first' do
      it 'returns true when after is present' do
        result = instance.send(:calculate_has_previous_page, false, { first: 10, after: 'cursor' })
        expect(result).to be true
      end

      it 'returns false when after is not present' do
        result = instance.send(:calculate_has_previous_page, false, { first: 10 })
        expect(result).to be false
      end
    end
  end
end

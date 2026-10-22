# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::OffsetCursorPagination, feature_category: :portfolio_management do
  let_it_be(:users) { create_list(:user, 5) }

  let(:scope) { User.id_in(users).order(id: :asc) }
  let(:cursor) { nil }
  let(:per_page) { 2 }

  subject(:paginator) { described_class.new(scope: scope, cursor: cursor, per_page: per_page) }

  def cursor_for(offset)
    described_class::Converter.dump('offset' => offset)
  end

  def offset_of(cursor)
    described_class::Converter.parse(cursor)['offset']
  end

  shared_examples 'an offset-backed cursor pager' do
    context 'without a cursor' do
      it 'returns the first page and only a next cursor' do
        expect(paginator.records).to eq(users.first(2))
        expect(paginator.has_previous_page?).to be(false)
        expect(paginator.cursor_for_previous_page).to be_nil
        expect(offset_of(paginator.cursor_for_next_page)).to eq(2)
      end
    end

    context 'with a cursor in the middle' do
      let(:cursor) { cursor_for(2) }

      it 'returns that page with cursors in both directions' do
        expect(paginator.records).to eq(users[2, 2])
        expect(offset_of(paginator.cursor_for_previous_page)).to eq(0)
        expect(offset_of(paginator.cursor_for_next_page)).to eq(4)
      end
    end

    context 'with a cursor on the last page' do
      let(:cursor) { cursor_for(4) }

      it 'returns the remaining records and no next cursor' do
        expect(paginator.records).to eq([users.last])
        expect(paginator.has_next_page?).to be(false)
        expect(paginator.cursor_for_next_page).to be_nil
        expect(offset_of(paginator.cursor_for_previous_page)).to eq(2)
      end
    end

    context 'with a cursor on an exactly full last page' do
      let(:cursor) { cursor_for(4) }
      let(:per_page) { 1 }

      it 'returns no next cursor' do
        expect(paginator.records).to eq([users.last])
        expect(paginator.has_next_page?).to be(false)
        expect(paginator.cursor_for_next_page).to be_nil
      end
    end

    context 'with a cursor past the end' do
      let(:cursor) { cursor_for(50) }

      it 'returns an empty page and only a previous cursor' do
        expect(paginator.records).to be_empty
        expect(paginator.cursor_for_next_page).to be_nil
        expect(offset_of(paginator.cursor_for_previous_page)).to eq(48)
      end
    end

    context 'when per_page changes between requests' do
      let(:cursor) { cursor_for(3) }
      let(:per_page) { 5 }

      it 'clamps the previous cursor at the first row' do
        expect(paginator.records).to eq(users[3, 2])
        expect(offset_of(paginator.cursor_for_previous_page)).to eq(0)
      end
    end
  end

  context 'with an ActiveRecord relation' do
    it_behaves_like 'an offset-backed cursor pager'

    it 'fetches one row beyond the page and no count' do
      recorder = ActiveRecord::QueryRecorder.new { paginator.records }

      expect(recorder.count).to eq(1)
      expect(recorder.log.first).to include('LIMIT 3')
      expect(recorder.log.first).not_to include('COUNT')
    end
  end

  context 'with an array' do
    let(:scope) { users }

    it_behaves_like 'an offset-backed cursor pager'
  end

  describe 'per_page validation' do
    it 'accepts the maximum per_page' do
      pager = described_class.new(scope: scope, per_page: Kaminari.config.max_per_page)

      expect(pager.records).to eq(users)
      expect(pager.has_next_page?).to be(false)
    end

    it 'raises ArgumentError outside 1 and the maximum' do
      [0, -1, Kaminari.config.max_per_page + 1, nil, '20'].each do |per_page|
        expect { described_class.new(scope: scope, per_page: per_page) }.to raise_error(ArgumentError, /per_page/)
      end
    end
  end

  context 'with an unordered relation' do
    let(:scope) { User.id_in(users) }

    it 'raises ArgumentError' do
      expect { paginator }.to raise_error(ArgumentError, /must be ordered/)
    end
  end

  describe 'cursor validation' do
    where(:cursor) do
      [
        ['not base64 at all!'],
        [Base64.urlsafe_encode64('not json')],
        [Base64.urlsafe_encode64('[1]')],
        [described_class::Converter.dump('offset' => -1)],
        [described_class::Converter.dump('offset' => '2')],
        [described_class::Converter.dump('offset' => 10_001)],
        [described_class::Converter.dump('other' => 2)],
        [123]
      ]
    end

    with_them do
      it 'raises InvalidCursorError' do
        expect { paginator }.to raise_error(described_class::InvalidCursorError)
      end
    end

    it 'stops paging when the next page would start beyond the maximum offset' do
      scope = Array.new(10_030) { |i| i }
      pager = described_class.new(scope: scope, cursor: cursor_for(9_990), per_page: 20)

      expect(pager.records.size).to eq(20)
      expect(pager.has_next_page?).to be(false)
      expect(pager.cursor_for_next_page).to be_nil
    end

    it 'accepts the maximum offset' do
      expect(described_class.new(scope: scope, cursor: cursor_for(10_000), per_page: per_page).records).to be_empty
    end

    it 'treats a blank cursor as the first page' do
      blank_cursor = described_class.new(scope: scope, cursor: '', per_page: per_page)

      expect(blank_cursor.records).to eq(users.first(2))
      expect(blank_cursor.has_previous_page?).to be(false)
    end
  end
end

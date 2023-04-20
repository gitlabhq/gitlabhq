# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::BlamePagination, feature_category: :source_code_management do
  subject(:blame_pagination) { described_class.new(blob, blame_mode, params) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:commit) { project.repository.commit }
  let_it_be(:blob) { project.repository.blob_at('HEAD', 'README.md') }

  let(:blame_mode) do
    instance_double(
      'Gitlab::Git::BlameMode',
      'streaming?' => streaming_mode,
      'full?' => full_mode
    )
  end

  let(:params) { { page: page } }
  let(:page) { 1 }
  let(:streaming_mode) { false }
  let(:full_mode) { false }

  using RSpec::Parameterized::TableSyntax

  describe '#page' do
    subject { blame_pagination.page }

    where(:page, :expected_page) do
      nil | 1
      1   | 1
      5   | 5
      -1  | 1
      'a' | 1
    end

    with_them do
      it { is_expected.to eq(expected_page) }
    end
  end

  describe '#per_page' do
    subject { blame_pagination.per_page }

    it { is_expected.to eq(described_class::PAGINATION_PER_PAGE) }

    context 'when blame mode is streaming' do
      let(:streaming_mode) { true }

      it { is_expected.to eq(described_class::STREAMING_PER_PAGE) }
    end
  end

  describe '#total_pages' do
    subject { blame_pagination.total_pages }

    before do
      stub_const("#{described_class.name}::PAGINATION_PER_PAGE", 2)
    end

    it { is_expected.to eq(2) }
  end

  describe '#total_extra_pages' do
    subject { blame_pagination.total_extra_pages }

    before do
      stub_const("#{described_class.name}::PAGINATION_PER_PAGE", 2)
    end

    it { is_expected.to eq(1) }
  end

  describe '#pagination' do
    subject { blame_pagination.paginator }

    before do
      stub_const("#{described_class.name}::PAGINATION_PER_PAGE", 2)
    end

    it 'returns a pagination object' do
      is_expected.to be_kind_of(Kaminari::PaginatableArray)

      expect(subject.current_page).to eq(1)
      expect(subject.total_pages).to eq(2)
      expect(subject.total_count).to eq(4)
    end

    context 'when user disabled the pagination' do
      let(:full_mode) { true }

      it { is_expected.to be_nil }
    end

    context 'when user chose streaming' do
      let(:streaming_mode) { true }

      it { is_expected.to be_nil }
    end

    context 'when per_page is above the global max per page limit' do
      before do
        stub_const("#{described_class.name}::PAGINATION_PER_PAGE", 1000)
        allow(blob).to receive_message_chain(:data, :lines, :count) { 500 }
      end

      it 'returns a correct pagination object' do
        is_expected.to be_kind_of(Kaminari::PaginatableArray)

        expect(subject.current_page).to eq(1)
        expect(subject.total_pages).to eq(1)
        expect(subject.total_count).to eq(500)
      end
    end

    describe 'Pagination attributes' do
      where(:page, :current_page, :total_pages) do
        1 | 1 | 2
        2 | 2 | 2
        0 | 1 | 2 # Incorrect
      end

      with_them do
        it 'returns the correct pagination attributes' do
          expect(subject.current_page).to eq(current_page)
          expect(subject.total_pages).to eq(total_pages)
        end
      end
    end
  end

  describe '#blame_range' do
    subject { blame_pagination.blame_range }

    before do
      stub_const("#{described_class.name}::PAGINATION_PER_PAGE", 2)
    end

    where(:page, :expected_range) do
      1 | (1..2)
      2 | (3..4)
      0 | (1..2)
    end

    with_them do
      it { is_expected.to eq(expected_range) }
    end

    context 'when user disabled the pagination' do
      let(:full_mode) { true }

      it { is_expected.to be_nil }
    end

    context 'when streaming is enabled' do
      let(:streaming_mode) { true }

      before do
        stub_const("#{described_class.name}::STREAMING_FIRST_PAGE_SIZE", 1)
        stub_const("#{described_class.name}::STREAMING_PER_PAGE", 1)
      end

      where(:page, :expected_range) do
        1 | (1..1)
        2 | (2..2)
        0 | (1..1)
      end

      with_them do
        it { is_expected.to eq(expected_range) }
      end
    end
  end
end

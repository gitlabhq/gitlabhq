# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlameService, :aggregate_failures, feature_category: :source_code_management do
  subject(:service) { described_class.new(blob, commit, params) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:commit) { project.repository.commit }
  let_it_be(:blob) { project.repository.blob_at('HEAD', 'README.md') }

  let(:params) { { page: page } }
  let(:page) { nil }

  before do
    stub_const("#{described_class.name}::PER_PAGE", 2)
  end

  describe '#blame' do
    subject { service.blame }

    it 'returns a correct Gitlab::Blame object' do
      is_expected.to be_kind_of(Gitlab::Blame)

      expect(subject.blob).to eq(blob)
      expect(subject.commit).to eq(commit)
      expect(subject.range).to eq(1..2)
    end

    describe 'Pagination range calculation' do
      subject { service.blame.range }

      context 'with page = 1' do
        let(:page) { 1 }

        it { is_expected.to eq(1..2) }
      end

      context 'with page = 2' do
        let(:page) { 2 }

        it { is_expected.to eq(3..4) }
      end

      context 'with page = 3 (overlimit)' do
        let(:page) { 3 }

        it { is_expected.to eq(1..2) }
      end

      context 'with page = 0 (incorrect)' do
        let(:page) { 0 }

        it { is_expected.to eq(1..2) }
      end

      context 'when user disabled the pagination' do
        let(:params) { super().merge(no_pagination: 1) }

        it { is_expected.to be_nil }
      end

      context 'when feature flag disabled' do
        before do
          stub_feature_flags(blame_page_pagination: false)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#pagination' do
    subject { service.pagination }

    it 'returns a pagination object' do
      is_expected.to be_kind_of(Kaminari::PaginatableArray)

      expect(subject.current_page).to eq(1)
      expect(subject.total_pages).to eq(2)
      expect(subject.total_count).to eq(4)
    end

    context 'when user disabled the pagination' do
      let(:params) { super().merge(no_pagination: 1) }

      it { is_expected.to be_nil }
    end

    context 'when feature flag disabled' do
      before do
        stub_feature_flags(blame_page_pagination: false)
      end

      it { is_expected.to be_nil }
    end

    context 'when per_page is above the global max per page limit' do
      before do
        stub_const("#{described_class.name}::PER_PAGE", 1000)
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
      using RSpec::Parameterized::TableSyntax

      where(:page, :current_page, :total_pages) do
        1 | 1 | 2
        2 | 2 | 2
        3 | 1 | 2 # Overlimit
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
end

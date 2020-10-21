# frozen_string_literal: true

RSpec.shared_examples 'search results filtered by confidential' do
  context 'filter not provided (all behavior)' do
    let(:filters) { {} }

    context 'when Feature search_filter_by_confidential enabled' do
      it 'returns confidential and not confidential results', :aggregate_failures do
        expect(results.objects('issues')).to include confidential_result
        expect(results.objects('issues')).to include opened_result
      end
    end

    context 'when Feature search_filter_by_confidential not enabled' do
      before do
        stub_feature_flags(search_filter_by_confidential: false)
      end

      it 'returns confidential and not confidential results', :aggregate_failures do
        expect(results.objects('issues')).to include confidential_result
        expect(results.objects('issues')).to include opened_result
      end
    end
  end

  context 'confidential filter' do
    let(:filters) { { confidential: true } }

    context 'when Feature search_filter_by_confidential enabled' do
      it 'returns only confidential results', :aggregate_failures do
        expect(results.objects('issues')).to include confidential_result
        expect(results.objects('issues')).not_to include opened_result
      end
    end

    context 'when Feature search_filter_by_confidential not enabled' do
      before do
        stub_feature_flags(search_filter_by_confidential: false)
      end

      it 'returns confidential and not confidential results', :aggregate_failures do
        expect(results.objects('issues')).to include confidential_result
        expect(results.objects('issues')).to include opened_result
      end
    end
  end

  context 'not confidential filter' do
    let(:filters) { { confidential: false } }

    context 'when Feature search_filter_by_confidential enabled' do
      it 'returns not confidential results', :aggregate_failures do
        expect(results.objects('issues')).not_to include confidential_result
        expect(results.objects('issues')).to include opened_result
      end
    end

    context 'when Feature search_filter_by_confidential not enabled' do
      before do
        stub_feature_flags(search_filter_by_confidential: false)
      end

      it 'returns confidential and not confidential results', :aggregate_failures do
        expect(results.objects('issues')).to include confidential_result
        expect(results.objects('issues')).to include opened_result
      end
    end
  end
end

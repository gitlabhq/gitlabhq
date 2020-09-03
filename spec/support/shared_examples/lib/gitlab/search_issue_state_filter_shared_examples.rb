# frozen_string_literal: true

RSpec.shared_examples 'search issues scope filters by state' do
  context 'state not provided' do
    let(:filters) { {} }

    it 'returns opened and closed issues', :aggregate_failures do
      expect(results.objects('issues')).to include opened_issue
      expect(results.objects('issues')).to include closed_issue
    end
  end

  context 'all state' do
    let(:filters) { { state: 'all' } }

    it 'returns opened and closed issues', :aggregate_failures do
      expect(results.objects('issues')).to include opened_issue
      expect(results.objects('issues')).to include closed_issue
    end
  end

  context 'closed state' do
    let(:filters) { { state: 'closed' } }

    it 'returns only closed issues', :aggregate_failures do
      expect(results.objects('issues')).not_to include opened_issue
      expect(results.objects('issues')).to include closed_issue
    end
  end

  context 'opened state' do
    let(:filters) { { state: 'opened' } }

    it 'returns only opened issues', :aggregate_failures do
      expect(results.objects('issues')).to include opened_issue
      expect(results.objects('issues')).not_to include closed_issue
    end
  end

  context 'unsupported state' do
    let(:filters) { { state: 'hello' } }

    it 'returns only opened issues', :aggregate_failures do
      expect(results.objects('issues')).to include opened_issue
      expect(results.objects('issues')).to include closed_issue
    end
  end
end

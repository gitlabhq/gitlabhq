require 'spec_helper'

describe Integrations::MergeRequestService, services: true do
  let(:project) { create(:empty_project) }
  let(:service) { described_class.new(project, nil, params) }

  subject { service.execute }

  describe '#execute' do
    context 'looking up by IID' do
      let(:params) { { text: mr.iid } }
      let(:mr)     { create(:merge_request, source_project: project) }

      it 'returns the issue by ID' do
        expect(subject[:attachments].first[:fallback]).to eq mr.title
      end
    end

    context 'when searching with only one result' do
      let(:params)          { { text: merge_request.title[2..7] } }
      let!(:merge_request)  { create(:merge_request, source_project: project) }

      it 'returns the search results' do
        expect(subject[:attachments].first[:fallback]).to eq merge_request.title
      end
    end
  end
end

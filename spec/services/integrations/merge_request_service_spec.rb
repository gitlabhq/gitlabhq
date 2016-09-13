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
        expect(subject[:text]).to match /!\d+\s#{Regexp.quote(mr.title)}/
      end
    end

    context 'when searching with only one result' do
      let(:title)  { 'Aint this a String?' }
      let(:params) { { text: title[2..7] } }

      it 'returns the search results' do
        create(:merge_request, source_project: project, title: title)
        create(:merge_request, source_project: project)

        expect(subject[:text]).to match /!\d+\sAint\sthis/
      end
    end
  end
end

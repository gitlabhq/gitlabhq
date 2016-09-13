require 'spec_helper'

describe Integrations::IssueService, services: true do
  let(:project) { create(:empty_project) }
  let(:service) { described_class.new(project, nil, params) }

  subject { service.execute }

  describe '#execute' do
    context 'looking up by IID' do
      let(:issue)  { create(:issue, project: project) }
      let(:params) { { text: issue.iid } }

      it 'returns the issue by IID' do
        expect(subject[:text]).to match /#\d+\s#{Regexp.quote(issue.title)}/
      end

      context 'the IID is passed as string' do
        let(:params) { { text: issue.iid.to_s } }

        it 'returns the issue by IID' do
          expect(subject[:text]).to match /#\d+\s#{Regexp.quote(issue.title)}/
        end
      end
    end

    context 'when looking for a non existing IID' do
      let(:params) { { text: 123456 } }
      it "returns not found when the IID does not exist" do
        expect(subject[:text]).to match /404\ not\ found!/
      end
    end

    context 'when searching on query' do
      let(:params) { { text: 'Mepmep' } }

      it 'returns the search results' do
        create(:issue, project: project, title: 'Mepmep this title')
        create(:issue, project: project, title: 'this title Mepmep')

        expect(subject[:text]).to start_with "Search results for "
      end
    end
  end
end

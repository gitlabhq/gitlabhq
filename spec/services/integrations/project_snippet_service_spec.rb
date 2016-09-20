require 'spec_helper'

describe Integrations::ProjectSnippetService, services: true do
  let(:project) { create(:empty_project) }
  let(:service) { described_class.new(project, nil, params) }

  subject { service.execute }

  describe '#execute' do
    context 'looking up by ID' do
      let(:snippet) { create(:project_snippet, project: project) }
      let(:params) { { text: "$#{snippet.id}" } }

      it 'returns the snippet by ID' do
        expect(subject[:attachments].first[:fallback]).to eq snippet.title
      end
    end
  end
end

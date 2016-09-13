require 'spec_helper'

describe Integrations::ProjectSnippetService, services: true do
  let(:project) { create(:empty_project) }
  let(:service) { described_class.new(project, nil, params) }

  subject { service.execute }

  describe '#execute' do
    context 'looking up by ID' do
      let(:snippet) { create(:project_snippet, project: project) }
      let(:params) { { text: snippet.id } }

      it 'returns the issue by ID' do
        expect(subject[:text]).to match /\$\d+\s#{Regexp.quote(snippet.title)}/
      end
    end
  end
end

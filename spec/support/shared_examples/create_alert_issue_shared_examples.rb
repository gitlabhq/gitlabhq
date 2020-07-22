# frozen_string_literal: true

RSpec.shared_examples 'create alert issue sets issue labels' do
  let(:title) { IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES[:title] }
  let!(:label) { create(:label, project: project, title: title) }
  let(:label_service) { instance_double(IncidentManagement::CreateIncidentLabelService, execute: label_service_response) }

  before do
    allow(IncidentManagement::CreateIncidentLabelService).to receive(:new).with(project, user).and_return(label_service)
  end

  context 'when create incident label responds with success' do
    let(:label_service_response) { ServiceResponse.success(payload: { label: label }) }

    it 'adds label to issue' do
      expect(issue.labels).to eq([label])
    end
  end
end

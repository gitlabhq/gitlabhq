# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::Incidents::CreateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { User.alert_bot }
  let(:description) { 'Incident description' }

  describe '#execute' do
    subject(:create_incident) { described_class.new(project, user, title: title, description: description).execute }

    context 'when incident has title and description' do
      let(:title) { 'Incident title' }
      let(:new_issue) { Issue.last! }
      let(:label_title) { IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES[:title] }

      it 'responds with success' do
        expect(create_incident).to be_success
      end

      it 'creates an incident issue' do
        expect { create_incident }.to change(Issue, :count).by(1)
      end

      it 'created issue has correct attributes' do
        create_incident
        aggregate_failures do
          expect(new_issue.title).to eq(title)
          expect(new_issue.description).to eq(description)
          expect(new_issue.author).to eq(user)
          expect(new_issue.issue_type).to eq('incident')
          expect(new_issue.labels.map(&:title)).to eq([label_title])
        end
      end

      context 'when incident label does not exists' do
        it 'creates incident label' do
          expect { create_incident }.to change { project.labels.where(title: label_title).count }.by(1)
        end
      end

      context 'when incident label already exists' do
        let!(:label) { create(:label, project: project, title: label_title) }

        it 'does not create new labels' do
          expect { create_incident }.not_to change(Label, :count)
        end
      end
    end

    context 'when incident has no title' do
      let(:title) { '' }

      it 'does not create an issue' do
        expect { create_incident }.not_to change(Issue, :count)
      end

      it 'responds with errors' do
        expect(create_incident).to be_error
        expect(create_incident.message).to eq("Title can't be blank")
      end

      it 'result payload contains an Issue object' do
        expect(create_incident.payload[:issue]).to be_kind_of(Issue)
      end
    end
  end
end

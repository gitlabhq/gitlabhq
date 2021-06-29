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
      let(:label_title) { attributes_for(:label, :incident)[:title] }

      it 'responds with success' do
        expect(create_incident).to be_success
      end

      it 'creates an incident issue' do
        expect { create_incident }.to change(Issue, :count).by(1)
      end

      it 'created issue has correct attributes', :aggregate_failures do
        create_incident

        expect(new_issue.title).to eq(title)
        expect(new_issue.description).to eq(description)
        expect(new_issue.author).to eq(user)
      end

      it_behaves_like 'incident issue' do
        before do
          create_incident
        end

        let(:issue) { new_issue }

        include_examples 'has incident label'
      end

      context 'with default severity' do
        it 'sets the correct severity level to "unknown"' do
          create_incident
          expect(new_issue.severity).to eq(IssuableSeverity::DEFAULT)
        end
      end

      context 'with severity' do
        using RSpec::Parameterized::TableSyntax

        subject(:create_incident) { described_class.new(project, user, title: title, description: description, severity: severity).execute }

        where(:severity, :incident_severity) do
          'critical' | 'critical'
          'high'     | 'high'
          'medium'   | 'medium'
          'low'      | 'low'
          'unknown'  | 'unknown'
        end

        with_them do
          it 'sets the correct severity level' do
            create_incident
            expect(new_issue.severity).to eq(incident_severity)
          end
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

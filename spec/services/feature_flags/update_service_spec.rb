# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::UpdateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let(:user) { developer }
  let(:feature_flag) { create(:operations_feature_flag, project: project, active: true) }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  describe '#execute' do
    subject { described_class.new(project, user, params).execute(feature_flag) }

    let(:params) { { name: 'new_name' } }
    let(:audit_event_message) do
      AuditEvent.last.details[:custom_message]
    end

    it 'returns success status' do
      expect(subject[:status]).to eq(:success)
    end

    it 'creates audit event with correct message' do
      name_was = feature_flag.name

      expect { subject }.to change { AuditEvent.count }.by(1)
      expect(audit_event_message).to(
        eq("Updated feature flag <strong>new_name</strong>. "\
           "Updated name from <strong>\"#{name_was}\"</strong> "\
           "to <strong>\"new_name\"</strong>.")
      )
    end

    context 'with invalid params' do
      let(:params) { { name: nil } }

      it 'returns error status' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:http_status]).to eq(:bad_request)
      end

      it 'returns error messages' do
        expect(subject[:message]).to include("Name can't be blank")
      end

      it 'does not create audit event' do
        expect { subject }.not_to change { AuditEvent.count }
      end
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns error status' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq('Access Denied')
      end
    end

    context 'when nothing is changed' do
      let(:params) { {} }

      it 'returns success status' do
        expect(subject[:status]).to eq(:success)
      end

      it 'does not create audit event' do
        expect { subject }.not_to change { AuditEvent.count }
      end
    end

    context 'description is being changed' do
      let(:params) { { description: 'new description' } }

      it 'creates audit event with changed description' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to(
          include("Updated description from <strong>\"\"</strong>"\
                  " to <strong>\"new description\"</strong>.")
        )
      end
    end

    context 'when flag active state is changed' do
      let(:params) do
        {
          active: false
        }
      end

      it 'creates audit event about changing active state' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to(
          include('Updated active from <strong>"true"</strong> to <strong>"false"</strong>.')
        )
      end

      it 'executes hooks' do
        hook = create(:project_hook, :all_events_enabled, project: project)
        expect(WebHookWorker).to receive(:perform_async).with(hook.id, an_instance_of(Hash), 'feature_flag_hooks')

        subject
      end
    end

    context 'when scope active state is changed' do
      let(:params) do
        {
          scopes_attributes: [{ id: feature_flag.scopes.first.id, active: false }]
        }
      end

      it 'creates audit event about changing active state' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to(
          include("Updated rule <strong>*</strong> active state "\
                  "from <strong>true</strong> to <strong>false</strong>.")
        )
      end
    end

    context 'when scope is renamed' do
      let(:changed_scope) { feature_flag.scopes.create!(environment_scope: 'review', active: true) }
      let(:params) do
        {
          scopes_attributes: [{ id: changed_scope.id, environment_scope: 'staging' }]
        }
      end

      it 'creates audit event with changed name' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to(
          include("Updated rule <strong>staging</strong> environment scope "\
                  "from <strong>review</strong> to <strong>staging</strong>.")
        )
      end

      context 'when scope can not be updated' do
        let(:params) do
          {
            scopes_attributes: [{ id: changed_scope.id, environment_scope: '' }]
          }
        end

        it 'returns error status' do
          expect(subject[:status]).to eq(:error)
        end

        it 'returns error messages' do
          expect(subject[:message]).to include("Scopes environment scope can't be blank")
        end

        it 'does not create audit event' do
          expect { subject }.not_to change { AuditEvent.count }
        end
      end
    end

    context 'when scope is deleted' do
      let(:deleted_scope) { feature_flag.scopes.create!(environment_scope: 'review', active: true) }
      let(:params) do
        {
          scopes_attributes: [{ id: deleted_scope.id, '_destroy': true }]
        }
      end

      it 'creates audit event with deleted scope' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to include("Deleted rule <strong>review</strong>.")
      end

      context 'when scope can not be deleted' do
        before do
          allow(deleted_scope).to receive(:destroy).and_return(false)
        end

        it 'does not create audit event' do
          expect do
            subject
          end.to not_change { AuditEvent.count }.and raise_error(ActiveRecord::RecordNotDestroyed)
        end
      end
    end

    context 'when new scope is being added' do
      let(:new_environment_scope) { 'review' }
      let(:params) do
        {
          scopes_attributes: [{ environment_scope: new_environment_scope, active: true }]
        }
      end

      it 'creates audit event with new scope' do
        expected = 'Created rule <strong>review</strong> and set it as <strong>active</strong> '\
                   'with strategies <strong>[{"name"=>"default", "parameters"=>{}}]</strong>.'

        subject

        expect(audit_event_message).to include(expected)
      end

      context 'when scope can not be created' do
        let(:new_environment_scope) { '' }

        it 'returns error status' do
          expect(subject[:status]).to eq(:error)
        end

        it 'returns error messages' do
          expect(subject[:message]).to include("Scopes environment scope can't be blank")
        end

        it 'does not create audit event' do
          expect { subject }.not_to change { AuditEvent.count }
        end
      end
    end

    context 'when the strategy is changed' do
      let(:scope) do
        create(:operations_feature_flag_scope,
               feature_flag: feature_flag,
               environment_scope: 'sandbox',
               strategies: [{ name: "default", parameters: {} }])
      end

      let(:params) do
        {
          scopes_attributes: [{
            id: scope.id,
            environment_scope: 'sandbox',
            strategies: [{
              name: 'gradualRolloutUserId',
              parameters: {
                groupId: 'mygroup',
                percentage: "40"
              }
            }]
          }]
        }
      end

      it 'creates an audit event' do
        expected = %r{Updated rule <strong>sandbox</strong> strategies from <strong>.*</strong> to <strong>.*</strong>.}

        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to match(expected)
      end
    end
  end
end

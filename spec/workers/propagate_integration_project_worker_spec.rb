# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationProjectWorker, feature_category: :integrations do
  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project, group: group) }
    let_it_be(:project3) { create(:project, group: group) }
    let_it_be(:integration) { create(:redmine_integration, :instance) }

    let(:job_args) { [integration.id, project1.id, project3.id] }

    it_behaves_like 'an idempotent worker' do
      it 'calls to Integrations::Propagation::BulkCreateService' do
        expect(Integrations::Propagation::BulkCreateService).to receive(:new)
          .with(integration, match_array([project1, project2, project3]), 'project').twice
          .and_return(double(execute: nil))

        subject
      end

      context 'with a group integration' do
        let_it_be(:integration) { create(:redmine_integration, :group, group: group) }

        it 'calls to Integrations::Propagation::BulkCreateService' do
          expect(Integrations::Propagation::BulkCreateService).to receive(:new)
            .with(integration, match_array([project2, project3]), 'project').twice
            .and_return(double(execute: nil))

          subject
        end
      end
    end

    context 'with a project in another organization' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:project_in_other_org) { create(:project, organization: other_organization) }

      it 'does not pass the project to Integrations::Propagation::BulkCreateService' do
        expect(Integrations::Propagation::BulkCreateService).to receive(:new)
          .with(integration, match_array([project1, project2, project3]), 'project')
          .and_return(instance_double(Integrations::Propagation::BulkCreateService, execute: nil))

        described_class.new.perform(integration.id, project1.id, project_in_other_org.id)
      end
    end

    context 'when every project in the range already has the integration' do
      before do
        create(:redmine_integration, project: project1, inherit_from_id: integration.id)
      end

      it 'does not call Integrations::Propagation::BulkCreateService' do
        expect(Integrations::Propagation::BulkCreateService).not_to receive(:new)

        described_class.new.perform(integration.id, project1.id, project1.id)
      end

      it 'does not probe the batch with a LIMIT 1 query' do
        recorder = ActiveRecord::QueryRecorder.new do
          described_class.new.perform(integration.id, project1.id, project1.id)
        end

        expect(recorder.log.grep(/FROM "projects".*LIMIT 1/)).to be_empty
      end
    end

    context 'with an invalid integration id' do
      it 'returns without failure' do
        expect(Integrations::Propagation::BulkCreateService).not_to receive(:new)

        subject.perform(0, 1, 100)
      end
    end
  end
end

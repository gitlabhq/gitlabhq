# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationProjectWorker do
  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project, group: group) }
    let_it_be(:project3) { create(:project, group: group) }
    let_it_be(:integration) { create(:redmine_integration, :instance) }

    let(:job_args) { [integration.id, project1.id, project3.id] }

    it_behaves_like 'an idempotent worker' do
      it 'calls to BulkCreateIntegrationService' do
        expect(BulkCreateIntegrationService).to receive(:new)
          .with(integration, match_array([project1, project2, project3]), 'project').twice
          .and_return(double(execute: nil))

        subject
      end

      context 'with a group integration' do
        let_it_be(:integration) { create(:redmine_integration, group: group, project: nil) }

        it 'calls to BulkCreateIntegrationService' do
          expect(BulkCreateIntegrationService).to receive(:new)
            .with(integration, match_array([project2, project3]), 'project').twice
            .and_return(double(execute: nil))

          subject
        end
      end
    end

    context 'with an invalid integration id' do
      it 'returns without failure' do
        expect(BulkCreateIntegrationService).not_to receive(:new)

        subject.perform(0, 1, 100)
      end
    end
  end
end

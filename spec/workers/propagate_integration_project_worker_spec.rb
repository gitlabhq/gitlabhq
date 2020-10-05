# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PropagateIntegrationProjectWorker do
  describe '#perform' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:integration) { create(:redmine_service, :instance) }

    before do
      allow(BulkCreateIntegrationService).to receive(:new)
        .with(integration, match_array([project1, project2]), 'project')
        .and_return(double(execute: nil))
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [integration.id, project1.id, project2.id] }

      it 'calls to BulkCreateIntegrationService' do
        expect(BulkCreateIntegrationService).to receive(:new)
          .with(integration, match_array([project1, project2]), 'project')
          .and_return(double(execute: nil))

        subject
      end
    end

    context 'with an invalid integration id' do
      it 'returns without failure' do
        expect(BulkCreateIntegrationService).not_to receive(:new)

        subject.perform(0, project1.id, project2.id)
      end
    end
  end
end

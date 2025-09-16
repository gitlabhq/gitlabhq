# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Refresh::WebHooksWorker, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:worker) { described_class.new }
  let(:project_id) { project.id }
  let(:user_id) { user.id }
  let(:oldrev) { 'old_sha' }
  let(:newrev) { 'new_sha' }
  let(:ref) { 'refs/heads/master' }

  describe '#perform' do
    let(:service_instance) { instance_double(MergeRequests::Refresh::WebHooksService) }

    context 'when project and user exist' do
      before do
        allow(MergeRequests::Refresh::WebHooksService).to receive(:new)
          .with(project: project, current_user: user)
          .and_return(service_instance)
        allow(service_instance).to receive(:execute)
      end

      it 'creates the service with correct parameters' do
        expect(MergeRequests::Refresh::WebHooksService).to receive(:new)
          .with(project: project, current_user: user)
          .and_return(service_instance)

        worker.perform(project_id, user_id, oldrev, newrev, ref)
      end

      it 'calls execute on the service with correct parameters' do
        expect(service_instance).to receive(:execute).with(oldrev, newrev, ref)

        worker.perform(project_id, user_id, oldrev, newrev, ref)
      end
    end

    context 'when project does not exist' do
      let(:project_id) { non_existing_record_id }

      it 'returns early without creating service' do
        expect(MergeRequests::Refresh::WebHooksService).not_to receive(:new)

        worker.perform(project_id, user_id, oldrev, newrev, ref)
      end

      it 'does not raise an error' do
        expect { worker.perform(project_id, user_id, oldrev, newrev, ref) }.not_to raise_error
      end
    end

    context 'when user does not exist' do
      let(:user_id) { non_existing_record_id }

      it 'returns early without creating service' do
        expect(MergeRequests::Refresh::WebHooksService).not_to receive(:new)

        worker.perform(project_id, user_id, oldrev, newrev, ref)
      end

      it 'does not raise an error' do
        expect { worker.perform(project_id, user_id, oldrev, newrev, ref) }.not_to raise_error
      end
    end

    context 'when both project and user do not exist' do
      let(:project_id) { non_existing_record_id }
      let(:user_id) { non_existing_record_id }

      it 'returns early without creating service' do
        expect(MergeRequests::Refresh::WebHooksService).not_to receive(:new)

        worker.perform(project_id, user_id, oldrev, newrev, ref)
      end
    end
  end
end

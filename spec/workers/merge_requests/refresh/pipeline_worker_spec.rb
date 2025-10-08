# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Refresh::PipelineWorker, feature_category: :code_review_workflow do
  describe '#perform' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }
    let(:worker) { described_class.new }
    let(:oldrev) { 'old_sha' }
    let(:newrev) { 'new_sha' }
    let(:ref) { 'refs/heads/master' }
    let(:params) { {} }

    subject(:execute) { worker.perform(project.id, user.id, oldrev, newrev, ref, params) }

    before_all do
      project.add_developer(user)
    end

    context 'when all records exist' do
      it 'calls the pipeline service with empty params' do
        expect_next_instance_of(MergeRequests::Refresh::PipelineService,
          project: project, current_user: user, params: { push_options: nil, gitaly_context: nil }) do |instance|
          expect(instance)
            .to receive(:execute)
            .with(oldrev, newrev, ref)
        end

        execute
      end

      context 'when params contains push_options' do
        let(:params) { { 'push_options' => { 'ci' => { 'skip' => true } } } }

        it 'calls the pipeline service with push_options' do
          expect_next_instance_of(MergeRequests::Refresh::PipelineService,
            project: project,
            current_user: user,
            params: { push_options: { 'ci' => { 'skip' => true } }, gitaly_context: nil }) do |instance|
            expect(instance)
              .to receive(:execute)
              .with(oldrev, newrev, ref)
          end

          execute
        end
      end

      context 'when params contains gitaly_context' do
        let(:params) { { 'gitaly_context' => { 'user_id' => user.id } } }

        it 'calls the pipeline service with gitaly_context' do
          expect_next_instance_of(MergeRequests::Refresh::PipelineService,
            project: project, current_user: user,
            params: { push_options: nil, gitaly_context: { 'user_id' => user.id } }) do |instance|
            expect(instance)
              .to receive(:execute)
              .with(oldrev, newrev, ref)
          end

          execute
        end
      end

      context 'when params contains both push_options and gitaly_context' do
        let(:params) do
          {
            'push_options' => { 'ci' => { 'skip' => true } },
            'gitaly_context' => { 'user_id' => user.id }
          }
        end

        it 'calls the pipeline service with both parameters' do
          expect_next_instance_of(MergeRequests::Refresh::PipelineService,
            project: project, current_user: user,
            params: {
              push_options: { 'ci' => { 'skip' => true } },
              gitaly_context: { 'user_id' => user.id }
            }) do |instance|
            expect(instance)
              .to receive(:execute)
              .with(oldrev, newrev, ref)
          end

          execute
        end
      end
    end

    shared_examples 'when a record does not exist' do
      it 'does not call the pipeline service' do
        expect(MergeRequests::Refresh::PipelineService).not_to receive(:new)

        expect { execute }.not_to raise_exception
      end
    end

    context 'when the project does not exist' do
      subject(:execute) { worker.perform(-1, user.id, oldrev, newrev, ref, params) }

      it_behaves_like 'when a record does not exist'
    end

    context 'when the user does not exist' do
      subject(:execute) { worker.perform(project.id, -1, oldrev, newrev, ref, params) }

      it_behaves_like 'when a record does not exist'
    end

    describe 'error handling in service' do
      context 'when pipeline service raises an error' do
        before do
          allow_next_instance_of(MergeRequests::Refresh::PipelineService) do |service|
            allow(service).to receive(:execute).and_raise(StandardError, 'Pipeline creation failed')
          end
        end

        it 'allows the error to propagate' do
          expect { execute }.to raise_error(StandardError, 'Pipeline creation failed')
        end
      end
    end
  end
end

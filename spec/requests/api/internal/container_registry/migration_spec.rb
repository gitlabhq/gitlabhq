# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::ContainerRegistry::Migration, :aggregate_failures, feature_category: :database do
  let_it_be_with_reload(:repository) { create(:container_repository) }

  let(:secret_token) { 'secret_token' }
  let(:sent_token) { secret_token }
  let(:repository_path) { repository.path }
  let(:status) { 'pre_import_complete' }
  let(:params) { { path: repository.path, status: status } }

  before do
    allow(Gitlab.config.registry).to receive(:notification_secret) { secret_token }
  end

  describe 'PUT /internal/registry/repositories/:path/migration/status' do
    subject do
      put api("/internal/registry/repositories/#{repository_path}/migration/status"),
          params: params,
          headers: { 'Authorization' => sent_token }
    end

    shared_examples 'returning an error' do |with_message: nil, returning_status: :bad_request|
      it "returns bad request response" do
        expect { subject }
          .not_to change { repository.reload.migration_state }

        expect(response).to have_gitlab_http_status(returning_status)
        expect(response.body).to include(with_message) if with_message
      end
    end

    context 'with a valid sent token' do
      shared_examples 'updating the repository migration status' do |from:, to:|
        it "updates the migration status from #{from} to #{to}" do
          expect { subject }
            .to change { repository.reload.migration_state }.from(from).to(to)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with status pre_import_complete' do
        let(:status) { 'pre_import_complete' }

        it_behaves_like 'returning an error', with_message: 'Wrong migration state (default)'

        context 'with repository in pre_importing migration state' do
          let(:repository) { create(:container_repository, :pre_importing) }

          before do
            allow_next_found_instance_of(ContainerRepository) do |found_repository|
              allow(found_repository).to receive(:migration_import).and_return(:ok)
            end
          end

          it_behaves_like 'updating the repository migration status', from: 'pre_importing', to: 'importing'

          context 'with a failing transition' do
            before do
              allow_next_found_instance_of(ContainerRepository) do |found_repository|
                allow(found_repository).to receive(:finish_pre_import_and_start_import).and_return(false)
              end
            end

            it_behaves_like 'returning an error', with_message: "Couldn't transition from pre_importing to importing"
          end

          context 'with repository in importing migration state' do
            let(:repository) { create(:container_repository, :importing) }

            it 'returns ok and does not update the migration state' do
              expect { subject }
                .not_to change { repository.reload.migration_state }

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end
      end

      context 'with status import_complete' do
        let(:status) { 'import_complete' }

        it_behaves_like 'returning an error', with_message: 'Wrong migration state (default)'

        context 'with repository in importing migration state' do
          let(:repository) { create(:container_repository, :importing) }
          let(:transition_result) { true }

          it_behaves_like 'updating the repository migration status', from: 'importing', to: 'import_done'

          context 'with a failing transition' do
            before do
              allow_next_found_instance_of(ContainerRepository) do |found_repository|
                allow(found_repository).to receive(:finish_import).and_return(false)
              end
            end

            it_behaves_like 'returning an error', with_message: "Couldn't transition from importing to import_done"
          end
        end

        context 'with repository in pre_importing migration state' do
          let(:repository) { create(:container_repository, :pre_importing) }

          it_behaves_like 'updating the repository migration status', from: 'pre_importing', to: 'import_done'
        end
      end

      %w[pre_import_failed import_failed].each do |status|
        context 'with status pre_import_failed' do
          let(:status) { 'pre_import_failed' }

          it_behaves_like 'returning an error', with_message: 'Wrong migration state (default)'

          context 'with repository in importing migration state' do
            let(:repository) { create(:container_repository, :importing) }

            it_behaves_like 'updating the repository migration status', from: 'importing', to: 'import_aborted'
          end

          context 'with repository in pre_importing migration state' do
            let(:repository) { create(:container_repository, :pre_importing) }

            it_behaves_like 'updating the repository migration status', from: 'pre_importing', to: 'import_aborted'
          end

          context 'with repository in unabortable migration state' do
            let(:repository) { create(:container_repository, :import_skipped) }

            it_behaves_like 'returning an error', with_message: 'Wrong migration state (import_skipped)'
          end
        end
      end

      context 'with a non existing path' do
        let(:repository_path) { 'this/does/not/exist' }

        it_behaves_like 'returning an error', returning_status: :not_found
      end

      context 'with invalid status' do
        let(:params) { super().merge(status: nil).compact }

        it_behaves_like 'returning an error', returning_status: :bad_request
      end

      context 'with invalid path' do
        let(:repository_path) { nil }

        it_behaves_like 'returning an error', returning_status: :not_found
      end

      context 'query read location' do
        it 'reads from the primary' do
          expect(ContainerRepository).to receive(:find_by_path!).and_wrap_original do |m, *args|
            expect(::Gitlab::Database::LoadBalancing::Session.current.use_primary?).to eq(true)
            m.call(*args)
          end

          subject
        end
      end
    end

    context 'with an invalid sent token' do
      let(:sent_token) { 'not_valid' }

      it_behaves_like 'returning an error', returning_status: :unauthorized
    end
  end
end

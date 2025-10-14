# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MarkPackageForDestructionService, :aggregate_failures, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:package) { create(:pypi_package) }

  describe '#execute' do
    let(:service) { described_class.new(container: package, current_user: user) }

    subject(:execute) { service.execute }

    context 'when the user is authorized' do
      before do
        package.project.add_maintainer(user)
      end

      context 'when it is successful' do
        it 'marks the package and package files as pending destruction' do
          expect(package).to receive(:mark_package_files_for_destruction).and_call_original
          expect(package).not_to receive(:sync_maven_metadata)
          expect(package).not_to receive(:sync_npm_metadata_cache)
          expect(Packages::Helm::BulkSyncHelmMetadataCacheService).not_to receive(:new)
          expect { execute }.to change { package.status }.from('default').to('pending_destruction')
        end

        it 'returns a success ServiceResponse' do
          response = execute

          expect(response).to be_a(ServiceResponse)
          expect(response).to be_success
          expect(response.message).to eq("Package was successfully marked as pending destruction")
        end
      end

      context 'when it is not successful' do
        before do
          allow(package).to receive(:pending_destruction!).and_raise(StandardError, "test")
        end

        it 'returns an error ServiceResponse' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(StandardError),
            project_id: package.project_id,
            package_id: package.id
          )

          response = execute

          expect(package).not_to receive(:sync_maven_metadata)
          expect(package).not_to receive(:sync_npm_metadata_cache)
          expect(Packages::Helm::BulkSyncHelmMetadataCacheService).not_to receive(:new)
          expect(response).to be_a(ServiceResponse)
          expect(response).to be_error
          expect(response.message).to eq("Failed to mark the package as pending destruction")
          expect(response.status).to eq(:error)
        end
      end

      context 'with npm package' do
        let_it_be_with_reload(:package) { create(:npm_package) }

        it 'returns a success ServiceResponse' do
          expect(package).to receive(:sync_npm_metadata_cache).and_call_original
          expect(execute).to be_success
        end
      end

      context 'with helm package' do
        let_it_be_with_reload(:package) { create(:helm_package) }
        let(:expected_metadatum) { package.package_files.first.helm_file_metadatum }

        before do
          allow(Packages::Helm::CreateMetadataCacheWorker).to receive(:bulk_perform_async_with_contexts)
        end

        it 'enqueues a sync worker job', :aggregate_failures do
          execute

          expect(::Packages::Helm::CreateMetadataCacheWorker)
            .to have_received(:bulk_perform_async_with_contexts) do |metadata, arguments_proc:, context_proc:|
              expect(metadata.map(&:channel)).to match_array([expected_metadatum.channel])

              expect(arguments_proc.call(expected_metadatum)).to eq(
                [expected_metadatum.project_id, expected_metadatum.channel]
              )
              expect(context_proc.call(expected_metadatum)).to eq(project: package.project, user: user)
            end
        end
      end

      context 'with maven package' do
        let_it_be_with_reload(:package) { create(:maven_package) }

        it 'returns a success ServiceResponse' do
          expect(package).to receive(:sync_maven_metadata).and_call_original
          expect(execute).to be_success
        end
      end
    end

    context 'when the user is not authorized' do
      it 'returns an error ServiceResponse' do
        response = execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq("You don't have access to this package")
        expect(response.status).to eq(:error)
      end
    end
  end
end

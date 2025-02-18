# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MarkPackageForDestructionService, :aggregate_failures, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:package) { create(:pypi_package) }

  describe '#execute' do
    subject(:service) { described_class.new(container: package, current_user: user) }

    context 'when the user is authorized' do
      before do
        package.project.add_maintainer(user)
      end

      context 'when it is successful' do
        it 'marks the package and package files as pending destruction' do
          expect(package).to receive(:mark_package_files_for_destruction).and_call_original
          expect(package).not_to receive(:sync_maven_metadata)
          expect(package).not_to receive(:sync_npm_metadata_cache)
          expect { service.execute }.to change { package.status }.from('default').to('pending_destruction')
        end

        it 'returns a success ServiceResponse' do
          response = service.execute

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

          response = service.execute

          expect(package).not_to receive(:sync_maven_metadata)
          expect(package).not_to receive(:sync_npm_metadata_cache)
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
          expect(service.execute).to be_success
        end
      end

      context 'with maven package' do
        let_it_be_with_reload(:package) { create(:maven_package) }

        it 'returns a success ServiceResponse' do
          expect(package).to receive(:sync_maven_metadata).and_call_original
          expect(service.execute).to be_success
        end
      end
    end

    context 'when the user is not authorized' do
      it 'returns an error ServiceResponse' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq("You don't have access to this package")
        expect(response.status).to eq(:error)
      end
    end
  end
end

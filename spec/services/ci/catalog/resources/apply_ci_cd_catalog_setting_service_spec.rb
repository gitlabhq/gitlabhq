# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::ApplyCiCdCatalogSettingService, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :catalog_resource_with_components) }

  let(:service) { described_class.new(project, user, enabled: enabled) }

  before_all do
    project.add_owner(user)
  end

  describe '#execute' do
    context 'when enabled is nil' do
      let(:enabled) { nil }

      it 'is a no-op and returns success' do
        expect(::Ci::Catalog::Resources::CreateService).not_to receive(:new)
        expect(::Ci::Catalog::Resources::DestroyService).not_to receive(:new)

        expect(service.execute).to be_success
        expect(project.reload.catalog_resource).to be_nil
      end
    end

    context 'when enabling the setting' do
      let(:enabled) { true }

      it 'creates a catalog resource' do
        response = service.execute

        expect(response).to be_success
        expect(project.reload.catalog_resource).to be_present
      end

      context 'when the catalog resource already exists' do
        before do
          create(:ci_catalog_resource, project: project)
        end

        it 'is a no-op and does not call the create service' do
          expect(::Ci::Catalog::Resources::CreateService).not_to receive(:new)

          expect(service.execute).to be_success
        end
      end

      context 'when the project has no description' do
        before do
          project.update!(description: nil)
        end

        it 'returns an error and does not create a catalog resource' do
          expect(::Ci::Catalog::Resources::CreateService).not_to receive(:new)

          response = service.execute

          expect(response).to be_error
          expect(response.message).to eq(described_class::DESCRIPTION_REQUIRED_MESSAGE)
          expect(project.reload.catalog_resource).to be_nil
        end
      end

      context 'when the create service returns an error' do
        it 'returns the error and does not reset the association' do
          error = ServiceResponse.error(message: 'not valid')
          expect_next_instance_of(::Ci::Catalog::Resources::CreateService, project, user) do |create_service|
            expect(create_service).to receive(:execute).and_return(error)
          end

          expect(service.execute).to eq(error)
        end
      end
    end

    context 'when disabling the setting' do
      let(:enabled) { false }

      context 'when the project is a catalog resource' do
        before do
          create(:ci_catalog_resource, project: project)
        end

        it 'destroys the catalog resource' do
          response = service.execute

          expect(response).to be_success
          expect(project.reload.catalog_resource).to be_nil
        end
      end

      context 'when the project is not a catalog resource' do
        it 'is a no-op and does not call the destroy service' do
          expect(::Ci::Catalog::Resources::DestroyService).not_to receive(:new)

          expect(service.execute).to be_success
        end
      end
    end

    context 'with an unauthorized user' do
      let(:enabled) { true }
      let(:service) { described_class.new(project, create(:user), enabled: enabled) }

      it 'raises an AccessDeniedError from the underlying service' do
        expect { service.execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end

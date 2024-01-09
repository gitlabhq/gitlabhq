# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::DestroyService, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :catalog_resource_with_components) }
  let_it_be(:catalog_resource) { create(:ci_catalog_resource, project: project) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'with an unauthorized user' do
      it 'raises an AccessDeniedError' do
        expect { service.execute(catalog_resource) }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'with an authorized user' do
      before_all do
        project.add_owner(user)
      end

      it 'destroys a catalog resource' do
        expect(project.catalog_resource).to eq(catalog_resource)

        response = service.execute(catalog_resource)

        expect(project.reload.catalog_resource).to be_nil
        expect(response.status).to be(:success)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::CreateService, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :catalog_resource_with_components) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'with an unauthorized user' do
      it 'raises an AccessDeniedError' do
        expect { service.execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'with an authorized user' do
      before_all do
        project.add_owner(user)
      end

      context 'and a valid project' do
        it 'creates a catalog resource' do
          response = service.execute

          expect(response.payload.project).to eq(project)
          expect(response.payload).to be_unverified
        end

        context 'when the project is in a verified namespace' do
          let_it_be(:verified_namespace) do
            create(:catalog_verified_namespace, :gitlab_partner_maintained, namespace: project.root_namespace)
          end

          it "saves the resource with the namespace's verification level" do
            response = service.execute

            expect(response.payload).to be_gitlab_partner_maintained
          end
        end
      end

      context 'with an invalid catalog resource' do
        it 'does not save the catalog resource' do
          catalog_resource = instance_double(::Ci::Catalog::Resource,
            valid?: false,
            errors: instance_double(ActiveModel::Errors, full_messages: ['not valid']))
          allow(::Ci::Catalog::Resource).to receive(:new).and_return(catalog_resource)

          response = service.execute

          expect(response.message).to eq('not valid')
        end
      end
    end
  end
end

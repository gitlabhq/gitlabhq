# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DeletePagesDeployment mutation', feature_category: :pages do
  include GraphqlHelpers

  let_it_be(:project_maintainer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: project_maintainer) }
  let(:pages_deployment) { create(:pages_deployment, project: project) }
  let(:pages_deployment_id) { pages_deployment.to_global_id.to_s }

  let(:mutation) do
    <<~GRAPHQL
      mutation DeletePagesDeployment {
        deletePagesDeployment(input: { id: "#{pages_deployment_id}" }) {
          pagesDeployment {
            id
            active
            deletedAt
          }
          errors
        }
      }
    GRAPHQL
  end

  before do
    post_graphql(mutation, current_user: current_user)
    pages_deployment.reload
  end

  describe 'user is authorized' do
    let(:current_user) { project_maintainer }

    it 'deactivates the deployment' do
      expect(pages_deployment.active?).to be(false)
    end

    it 'does not throw an error' do
      expect(graphql_errors).to be_nil
    end

    describe 'returned pages deployment', :freeze_time do
      let(:returned_pages_deployment) { graphql_data_at(:deletePagesDeployment, :pages_deployment) }

      it 'has the correct ID' do
        expect(returned_pages_deployment["id"]).to eq(pages_deployment.to_global_id.to_s)
      end

      it 'has attribute active:false' do
        expect(returned_pages_deployment["active"]).to be(false)
      end

      it 'has deleted_at set to the deletion time' do
        expect(returned_pages_deployment["deletedAt"]).to eq(Time.now.utc.iso8601)
      end
    end
  end

  describe 'user is not authorized' do
    let(:current_user) { guest }

    it 'does not deactivate the deployment' do
      expect(pages_deployment.active?).to be(true)
    end

    it 'returns an error' do
      expect(graphql_errors.to_s)
        .to include("The resource that you are attempting to access does not exist or you don't have permission")
    end
  end
end

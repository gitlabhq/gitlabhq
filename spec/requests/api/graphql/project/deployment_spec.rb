# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Deployment query', feature_category: :continuous_delivery do
  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:deployment) { create(:deployment, environment: environment, project: project) }

  subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

  let(:user) { developer }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          deployment(iid: #{deployment.iid}) {
            id
            iid
            ref
            tag
            sha
            createdAt
            updatedAt
            finishedAt
            status
          }
        }
      }
    )
  end

  it 'returns the deployment of the project' do
    deployment_data = subject.dig('data', 'project', 'deployment')

    expect(deployment_data['iid']).to eq(deployment.iid.to_s)
  end

  context 'when user is guest' do
    let(:user) { guest }

    it 'returns nothing' do
      deployment_data = subject.dig('data', 'project', 'deployment')

      expect(deployment_data).to be_nil
    end
  end
end

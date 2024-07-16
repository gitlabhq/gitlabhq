# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ArtifactDestroy', feature_category: :job_artifacts do
  include GraphqlHelpers

  let(:user) { create(:user) }
  let(:artifact) { create(:ci_job_artifact) }

  let(:mutation) do
    variables = {
      id: artifact.to_global_id.to_s
    }
    graphql_mutation(:artifact_destroy, variables, 'errors')
  end

  it 'returns an error if the user is not allowed to destroy the artifact' do
    post_graphql_mutation(mutation, current_user: user)

    expect(graphql_errors).not_to be_empty
  end

  context 'when the user is allowed to destroy the artifact' do
    before do
      artifact.job.project.add_maintainer(user)
    end

    it 'destroys the artifact' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect { artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns error if destory fails' do
      allow_next_found_instance_of(Ci::JobArtifact) do |instance|
        allow(instance).to receive(:destroy).and_return(false)
        allow(instance).to receive_message_chain(:errors, :full_messages).and_return(['cannot be removed'])
      end

      post_graphql_mutation(mutation, current_user: user)

      expect(graphql_data_at(:artifact_destroy, :errors)).to contain_exactly('cannot be removed')
    end
  end
end

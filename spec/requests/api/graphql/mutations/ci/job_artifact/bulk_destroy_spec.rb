# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'BulkDestroy', feature_category: :job_artifacts do
  include GraphqlHelpers

  let(:maintainer) { create(:user) }
  let(:developer) { create(:user) }
  let(:first_artifact) { create(:ci_job_artifact) }
  let(:second_artifact) { create(:ci_job_artifact, project: project) }
  let(:second_artifact_another_project) { create(:ci_job_artifact) }
  let(:project) { first_artifact.job.project }
  let(:ids) { [first_artifact.to_global_id.to_s] }
  let(:not_authorized_project_error_message) do
    "The resource that you are attempting to access " \
      "does not exist or you don't have permission to perform this action"
  end

  let(:mutation) do
    variables = {
      project_id: project.to_global_id.to_s,
      ids: ids
    }
    graphql_mutation(:bulk_destroy_job_artifacts, variables, <<~FIELDS)
      destroyedCount
      destroyedIds
      errors
    FIELDS
  end

  let(:mutation_response) { graphql_mutation_response(:bulk_destroy_job_artifacts) }

  it 'fails to destroy the artifact if a user not in a project' do
    post_graphql_mutation(mutation, current_user: maintainer)

    expect(graphql_errors).to include(
      a_hash_including('message' => not_authorized_project_error_message)
    )

    expect(first_artifact.reload).to be_persisted
  end

  context "when the user is a developer in a project" do
    before do
      project.add_developer(developer)
    end

    it 'fails to destroy the artifact' do
      post_graphql_mutation(mutation, current_user: developer)

      expect(graphql_errors).to include(
        a_hash_including('message' => not_authorized_project_error_message)
      )

      expect(response).to have_gitlab_http_status(:success)
      expect(first_artifact.reload).to be_persisted
    end
  end

  context "when the user is a maintainer in a project" do
    before do
      project.add_maintainer(maintainer)
    end

    shared_examples 'failing mutation' do
      it 'rejects the request' do
        post_graphql_mutation(mutation, current_user: maintainer)

        expect(graphql_errors(mutation_response)).to include(expected_error_message)

        expected_not_found_artifacts.each do |artifact|
          expect { artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        expected_found_artifacts.each do |artifact|
          expect(artifact.reload).to be_persisted
        end
      end
    end

    it 'destroys the artifact' do
      post_graphql_mutation(mutation, current_user: maintainer)

      expect(mutation_response).to include("destroyedCount" => 1, "destroyedIds" => [gid_string(first_artifact)])
      expect(response).to have_gitlab_http_status(:success)
      expect { first_artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "and one artifact doesn't belong to the project" do
      let(:not_owned_artifact) { create(:ci_job_artifact) }
      let(:ids) { [first_artifact.to_global_id.to_s, not_owned_artifact.to_global_id.to_s] }
      let(:expected_error_message) { "Not all artifacts belong to requested project" }
      let(:expected_not_found_artifacts) { [] }
      let(:expected_found_artifacts) { [first_artifact, not_owned_artifact] }

      it_behaves_like 'failing mutation'
    end

    context "and multiple artifacts belong to the maintainer's project" do
      let(:ids) { [first_artifact.to_global_id.to_s, second_artifact.to_global_id.to_s] }

      it 'destroys all artifacts' do
        post_graphql_mutation(mutation, current_user: maintainer)

        expect(mutation_response).to include(
          "destroyedCount" => 2,
          "destroyedIds" => match_array([gid_string(first_artifact), gid_string(second_artifact)])
        )

        expect(response).to have_gitlab_http_status(:success)
        expect { first_artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { second_artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "and one artifact belongs to a different maintainer's project" do
      let(:ids) { [first_artifact.to_global_id.to_s, second_artifact_another_project.to_global_id.to_s] }
      let(:expected_found_artifacts) { [first_artifact, second_artifact_another_project] }
      let(:expected_not_found_artifacts) { [] }
      let(:expected_error_message) { "Not all artifacts belong to requested project" }

      it_behaves_like 'failing mutation'
    end

    context "and not found" do
      let(:ids) { [first_artifact.to_global_id.to_s, second_artifact.to_global_id.to_s] }
      let(:not_found_ids) { expected_not_found_artifacts.map(&:id).join(',') }
      let(:expected_error_message) { "Artifacts (#{not_found_ids}) not found" }

      before do
        expected_not_found_artifacts.each(&:destroy!)
      end

      context "with one artifact" do
        let(:expected_not_found_artifacts) { [second_artifact] }
        let(:expected_found_artifacts) { [first_artifact] }

        it_behaves_like 'failing mutation'
      end

      context "with all artifact" do
        let(:expected_not_found_artifacts) { [first_artifact, second_artifact] }
        let(:expected_found_artifacts) { [] }

        it_behaves_like 'failing mutation'
      end
    end

    context 'when empty request' do
      before do
        project.add_maintainer(maintainer)
      end

      context 'with nil value' do
        let(:ids) { nil }

        it 'does nothing and returns empty answer' do
          post_graphql_mutation(mutation, current_user: maintainer)

          expect_graphql_errors_to_include(/was provided invalid value for ids \(Expected value to not be null\)/)
        end
      end

      context 'with empty array' do
        let(:ids) { [] }

        it 'raises argument error' do
          post_graphql_mutation(mutation, current_user: maintainer)

          expect_graphql_errors_to_include(/IDs array of job artifacts can not be empty/)
        end
      end
    end

    def gid_string(object)
      Gitlab::GlobalId.build(object, id: object.id).to_s
    end
  end
end

# frozen_string_literal: true
require "spec_helper"

RSpec.describe "uploading designs", feature_category: :design_management do
  include GraphqlHelpers
  include DesignManagementTestHelpers
  include WorkhorseHelpers

  let(:current_user) { create(:user) }
  let(:issue) { create(:issue) }
  let(:project) { issue.project }
  let(:files) { [fixture_file_upload("spec/fixtures/dk.png")] }
  let(:variables) { {} }
  let(:mutation_response) { graphql_mutation_response(:design_management_upload) }

  def mutation
    input = {
      project_path: project.full_path,
      iid: issue.iid,
      files: files.dup
    }.merge(variables)
    graphql_mutation(:design_management_upload, input)
  end

  before do
    enable_design_management

    project.add_developer(current_user)
  end

  context 'when the input does not include a null value for each mapped file' do
    let(:operations) { { query: mutation.query, variables: mutation.variables.merge(files: []) } }
    let(:mapping) { { '1' => ['variables.files.0'] } }
    let(:params) do
      { '1' => files.first, operations: operations.to_json, map: mapping.to_json }
    end

    it 'returns an error' do
      workhorse_post_with_file(
        api('/', current_user, version: 'graphql'),
        params: params,
        file_key: '1'
      )

      expect(response).to have_attributes(
        code: eq('400'),
        body: include('out-of-bounds')
      )
    end
  end

  it "returns an error if the user is not allowed to upload designs" do
    post_graphql_mutation_with_uploads(mutation, current_user: create(:user))

    expect(graphql_errors).to be_present
  end

  it "succeeds, and responds with the created designs" do
    post_graphql_mutation_with_uploads(mutation, current_user: current_user)

    expect(graphql_errors).not_to be_present

    expect(mutation_response).to include(
      "designs" => a_collection_containing_exactly(
        a_hash_including("filename" => "dk.png")
      )
    )
  end

  it "can respond with skipped designs" do
    2.times do
      post_graphql_mutation_with_uploads(mutation, current_user: current_user)
      files.each(&:rewind)
    end

    expect(mutation_response).to include(
      "skippedDesigns" => a_collection_containing_exactly(
        a_hash_including("filename" => "dk.png")
      )
    )
  end

  context "when the issue does not exist" do
    let(:variables) { { iid: "123" } }

    it "returns an error" do
      post_graphql_mutation_with_uploads(mutation, current_user: create(:user))

      expect(graphql_errors).not_to be_empty
    end
  end

  context "when saving the designs raises an error" do
    it "responds with errors" do
      expect_next_instance_of(::DesignManagement::SaveDesignsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :error, message: "Something went wrong" })
      end

      post_graphql_mutation_with_uploads(mutation, current_user: current_user)
      expect(mutation_response["errors"].first).to eq("Something went wrong")
    end
  end
end

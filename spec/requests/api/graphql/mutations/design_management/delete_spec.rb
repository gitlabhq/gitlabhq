# frozen_string_literal: true

require "spec_helper"

RSpec.describe "deleting designs", feature_category: :design_management do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let(:reporter) { create(:user) }
  let(:current_user) { reporter }
  let(:issue) { create(:issue) }
  let(:project) { issue.project }
  let(:designs) { create_designs }
  let(:variables) { {} }

  let(:mutation) do
    input = {
      project_path: project.full_path,
      iid: issue.iid,
      filenames: designs.map(&:filename)
    }.merge(variables)
    graphql_mutation(:design_management_delete, input)
  end

  let(:mutation_response) { graphql_mutation_response(:design_management_delete) }

  def mutate!
    post_graphql_mutation(mutation, current_user: current_user)
  end

  before do
    enable_design_management

    project.add_reporter(reporter)
  end

  shared_examples 'a failed request' do
    let(:the_error) { be_present }

    it 'reports an error' do
      mutate!

      expect(graphql_errors).to include(a_hash_including('message' => the_error))
    end
  end

  context 'the designs list is empty' do
    it_behaves_like 'a failed request' do
      let(:designs) { [] }
      let(:the_error) { a_string_matching %r{no filenames} }
    end
  end

  context 'the designs list contains filenames we cannot find' do
    it_behaves_like 'a failed request' do
      let(:designs) { %w[foo bar baz].map { |fn| double('file', filename: fn) } }
      let(:the_error) { a_string_matching %r{filenames were not found} }
    end
  end

  context 'the current user does not have reporter access' do
    it_behaves_like 'a failed request' do
      let(:current_user) { create(:user) }
      let(:the_error) { a_string_matching %r{you don't have permission} }
    end
  end

  context "when the issue does not exist" do
    it_behaves_like 'a failed request' do
      let(:variables) { { iid: "1234567890" } }
      let(:the_error) { a_string_matching %r{does not exist} }
    end
  end

  context "when saving the designs raises an error" do
    let(:designs) { create_designs(1) }

    it "responds with errors" do
      expect_next_instance_of(::DesignManagement::DeleteDesignsService) do |service|
        expect(service)
          .to receive(:execute)
          .and_return({ status: :error, message: "Something went wrong" })
      end

      mutate!

      expect(mutation_response).to include('errors' => include(eq "Something went wrong"))
    end
  end

  context 'one of the designs is already deleted' do
    let(:designs) do
      create_designs(2).push(create(:design, :with_file, deleted: true, issue: issue))
    end

    it 'reports an error' do
      mutate!

      expect(graphql_errors).to be_present
    end
  end

  context 'when the user names designs to delete' do
    before do
      create_designs(1)
    end

    let!(:designs) { create_designs(2) }

    it 'deletes the designs' do
      expect { mutate! }
        .to change { issue.reset.designs.current.count }.from(3).to(1)
    end

    it 'has no errors' do
      mutate!

      expect(mutation_response).to include('errors' => be_empty)
    end
  end

  private

  def create_designs(how_many = 2)
    create_list(:design, how_many, :with_file, issue: issue)
  end
end

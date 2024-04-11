# frozen_string_literal: true

require "spec_helper"

RSpec.describe "updating designs", feature_category: :design_management do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be_with_reload(:design) { create(:design, description: 'old description', issue: issue) }
  let_it_be(:developer) { create(:user, developer_of: issue.project) }

  let(:user) { developer }
  let(:description) { 'new description' }

  let(:mutation) do
    input = {
      id: design.to_global_id.to_s,
      description: description
    }.compact

    graphql_mutation(:design_management_update, input, <<~FIELDS)
    errors
    design {
      description
      descriptionHtml
    }
    FIELDS
  end

  let(:update_design) { post_graphql_mutation(mutation, current_user: user) }
  let(:mutation_response) { graphql_mutation_response(:design_management_update) }

  before do
    enable_design_management
  end

  it 'updates design' do
    update_design

    expect(graphql_errors).not_to be_present
    expect(mutation_response).to eq(
      'errors' => [],
      'design' => {
        'description' => description,
        'descriptionHtml' => "<p data-sourcepos=\"1:1-1:15\" dir=\"auto\">#{description}</p>"
      }
    )
  end

  context 'when the user is not allowed to update designs' do
    let(:user) { create(:user) }

    it 'returns an error' do
      update_design

      expect(graphql_errors).to be_present
    end
  end

  context 'when update fails' do
    let(:description) { 'x' * 1_000_001 }

    it 'returns an error' do
      update_design

      expect(graphql_errors).not_to be_present
      expect(mutation_response).to eq(
        'errors' => ["Description is too long (maximum is 1000000 characters)"],
        'design' => {
          'description' => 'old description',
          'descriptionHtml' => '<p data-sourcepos="1:1-1:15" dir="auto">old description</p>'
        }
      )
    end
  end
end

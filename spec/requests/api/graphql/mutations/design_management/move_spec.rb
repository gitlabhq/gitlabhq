# frozen_string_literal: true
require "spec_helper"

RSpec.describe "moving designs", feature_category: :design_management do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:designs) { create_list(:design, 3, :with_versions, :with_relative_position, issue: issue) }
  let_it_be(:developer) { create(:user, developer_of: issue.project) }

  let(:user) { developer }

  let(:current_design) { designs.first }
  let(:previous_design) { designs.second }
  let(:next_design) { designs.third }
  let(:mutation_name) { :design_management_move }

  let(:mutation) do
    input = {
      id: current_design.to_global_id.to_s,
      previous: previous_design&.to_global_id&.to_s,
      next: next_design&.to_global_id&.to_s
    }.compact

    graphql_mutation(mutation_name, input, <<~FIELDS)
    errors
    designCollection {
      designs {
        nodes {
          filename
        }
      }
    }
    FIELDS
  end

  let(:move_designs) { post_graphql_mutation(mutation, current_user: user) }
  let(:mutation_response) { graphql_mutation_response(mutation_name) }

  before do
    enable_design_management
    designs.each(&:reset)
    issue.reset
  end

  shared_examples 'a successful move' do
    it 'does not error, and reports the current order' do
      move_designs

      expect(graphql_errors).not_to be_present

      expect(mutation_response).to eq(
        'errors' => [],
        'designCollection' => {
          'designs' => {
            'nodes' => new_order.map { |d| { 'filename' => d.filename } }
          }
        }
      )
    end
  end

  context 'the user is not allowed to move designs' do
    let(:user) { create(:user) }

    it 'returns an error' do
      move_designs

      expect(graphql_errors).to be_present
    end
  end

  context 'the neighbors do not have positions' do
    let!(:previous_design) { create(:design, :with_versions, issue: issue) }
    let!(:next_design) { create(:design, :with_versions, issue: issue) }

    let(:new_order) do
      [
        designs.second,
        designs.third,
        previous_design, current_design, next_design
      ]
    end

    it_behaves_like 'a successful move'

    it 'maintains the correct order in the presence of other unpositioned designs' do
      other_design = create(:design, :with_versions, issue: issue)

      move_designs
      moved_designs = mutation_response.dig('designCollection', 'designs', 'nodes')

      expect(moved_designs.map { |d| d['filename'] })
        .to eq([*new_order.map(&:filename), other_design.filename])
    end
  end

  context 'moving a design between two others' do
    let(:new_order) { [designs.second, designs.first, designs.third] }

    it_behaves_like 'a successful move'
  end

  context 'moving a design to the start' do
    let(:current_design) { designs.last }
    let(:next_design) { designs.first }
    let(:previous_design) { nil }
    let(:new_order) { [designs.last, designs.first, designs.second] }

    it_behaves_like 'a successful move'
  end

  context 'moving a design to the end' do
    let(:current_design) { designs.first }
    let(:next_design) { nil }
    let(:previous_design) { designs.last }
    let(:new_order) { [designs.second, designs.third, designs.first] }

    it_behaves_like 'a successful move'
  end
end

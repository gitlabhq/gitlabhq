# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::MoveDesignsService, feature_category: :design_management do
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:developer) { create(:user, developer_of: issue.project) }
  let_it_be(:designs) { create_list(:design, 3, :with_relative_position, issue: issue) }

  let(:project) { issue.project }

  let(:service) { described_class.new(current_user, params) }

  let(:params) do
    {
      current_design: current_design,
      previous_design: previous_design,
      next_design: next_design
    }
  end

  let(:current_user) { developer }
  let(:current_design) { nil }
  let(:previous_design) { nil }
  let(:next_design) { nil }

  before do
    enable_design_management
  end

  describe '#execute' do
    subject { service.execute }

    context 'the user cannot move designs' do
      let(:current_design) { designs.first }
      let(:current_user) { build_stubbed(:user) }

      it 'raises cannot_move', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446179' do
        expect(subject).to be_error.and(have_attributes(message: :cannot_move))
      end
    end

    context 'the designs are not distinct' do
      let(:current_design) { designs.first }
      let(:previous_design) { designs.first }

      it 'raises not_distinct' do
        expect(subject).to be_error.and(have_attributes(message: :not_distinct))
      end
    end

    context 'the designs are not on the same issue' do
      let(:current_design) { designs.first }
      let(:previous_design) { create(:design) }

      it 'raises not_same_issue' do
        expect(subject).to be_error.and(have_attributes(message: :not_same_issue))
      end
    end

    context 'no focus is passed' do
      let(:previous_design) { designs.second }
      let(:next_design) { designs.third }

      it 'raises no_focus' do
        expect(subject).to be_error.and(have_attributes(message: :no_focus))
      end
    end

    context 'no neighbours are passed' do
      let(:current_design) { designs.first }

      it 'raises no_neighbors' do
        expect(subject).to be_error.and(have_attributes(message: :no_neighbors))
      end
    end

    context 'moving a design with neighbours' do
      let(:current_design) { designs.first }
      let(:previous_design) { designs.second }
      let(:next_design) { designs.third }

      it 'repositions existing designs and correctly places the given design' do
        other_design1 = create(:design, issue: issue, relative_position: 10)
        other_design2 = create(:design, issue: issue, relative_position: 20)
        other_design3, other_design4 = create_list(:design, 2, issue: issue)

        expect(subject).to be_success

        expect(issue.designs.ordered).to eq(
          [
            # Existing designs which already had a relative_position set.
            # These should stay at the beginning, in the same order.
            other_design1,
            other_design2,

            # The designs we're passing into the service.
            # These should be placed between the existing designs, in the correct order.
            previous_design,
            current_design,
            next_design,

            # Existing designs which didn't have a relative_position set.
            # These should be placed at the end, in the order of their IDs.
            other_design3,
            other_design4
          ])
      end
    end
  end
end

# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::MoveDesignsService do
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:developer) { create(:user, developer_projects: [issue.project]) }
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

    context 'the feature is unavailable' do
      let(:current_design) { designs.first }
      let(:previous_design) { designs.second }
      let(:next_design) { designs.third }

      before do
        stub_feature_flags(reorder_designs: false)
      end

      it 'raises cannot_move' do
        expect(subject).to be_error.and(have_attributes(message: :cannot_move))
      end

      context 'but it is available on the current project' do
        before do
          stub_feature_flags(reorder_designs: issue.project)
        end

        it 'is successful' do
          expect(subject).to be_success
        end
      end
    end

    context 'the user cannot move designs' do
      let(:current_design) { designs.first }
      let(:current_user) { build_stubbed(:user) }

      it 'raises cannot_move' do
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

    context 'the designs are not adjacent' do
      let(:current_design) { designs.first }
      let(:previous_design) { designs.second }
      let(:next_design) { designs.third }

      it 'raises not_adjacent' do
        create(:design, issue: issue, relative_position: next_design.relative_position - 1)

        expect(subject).to be_error.and(have_attributes(message: :not_adjacent))
      end
    end

    context 'moving a design with neighbours' do
      let(:current_design) { designs.first }
      let(:previous_design) { designs.second }
      let(:next_design) { designs.third }

      it 'calls move_between and is successful' do
        expect(current_design).to receive(:move_between).with(previous_design, next_design)
        expect(subject).to be_success
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeData, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).inverse_of(:merge_data) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:merge_user).class_name('User').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:merge_request) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:merge_status) }
    it { is_expected.to validate_inclusion_of(:merge_status).in_array(described_class::MERGE_STATUSES.values) }
  end

  def merge_status_id(status)
    described_class::MERGE_STATUSES[status]
  end

  describe 'merge_status state machine' do
    subject(:merge_data) { create(:merge_requests_merge_data, merge_request: merge_request, project: project) }

    describe 'initial state' do
      it 'starts with unchecked status' do
        expect(merge_data.merge_status_name).to eq(:unchecked)
        expect(merge_data.unchecked?).to be_truthy
      end
    end

    describe 'state transitions' do
      subject(:merge_data) do
        create(:merge_requests_merge_data, merge_request: merge_request, merge_status: merge_status_id(merge_status))
      end

      shared_examples 'for an invalid state transition' do
        specify 'is not a valid state transition' do
          expect { transition! }.to raise_error(StateMachines::InvalidTransition)
        end
      end

      shared_examples 'for a valid state transition' do
        it 'is a valid state transition' do
          expect { transition! }
            .to change { merge_data.merge_status_name }
            .from(merge_status)
            .to(expected_merge_status)
        end
      end

      describe '#mark_as_preparing' do
        let(:expected_merge_status) { :preparing }

        def transition!
          merge_data.mark_as_preparing!
        end

        context 'when the status is unchecked' do
          let(:merge_status) { :unchecked }

          include_examples 'for a valid state transition'
        end

        context 'when the status is checking' do
          let(:merge_status) { :checking }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is can_be_merged' do
          let(:merge_status) { :can_be_merged }

          include_examples 'for a valid state transition'
        end

        context 'when the status is cannot_be_merged_recheck' do
          let(:merge_status) { :cannot_be_merged_recheck }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged' do
          let(:merge_status) { :cannot_be_merged }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged_rechecking' do
          let(:merge_status) { :cannot_be_merged_rechecking }

          include_examples 'for an invalid state transition'
        end
      end

      describe '#mark_as_unchecked' do
        def transition!
          merge_data.mark_as_unchecked!
        end

        context 'when the status is unchecked' do
          let(:merge_status) { :unchecked }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is checking' do
          let(:merge_status) { :checking }
          let(:expected_merge_status) { :unchecked }

          include_examples 'for a valid state transition'
        end

        context 'when the status is can_be_merged' do
          let(:merge_status) { :can_be_merged }
          let(:expected_merge_status) { :unchecked }

          include_examples 'for a valid state transition'
        end

        context 'when the status is cannot_be_merged_recheck' do
          let(:merge_status) { :cannot_be_merged_recheck }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged' do
          let(:merge_status) { :cannot_be_merged }
          let(:expected_merge_status) { :cannot_be_merged_recheck }

          include_examples 'for a valid state transition'
        end

        context 'when the status is cannot_be_merged_rechecking' do
          let(:merge_status) { :cannot_be_merged_rechecking }
          let(:expected_merge_status) { :cannot_be_merged_recheck }

          include_examples 'for a valid state transition'
        end
      end

      describe '#mark_as_checking' do
        def transition!
          merge_data.mark_as_checking!
        end

        context 'when the status is unchecked' do
          let(:merge_status) { :unchecked }
          let(:expected_merge_status) { :checking }

          include_examples 'for a valid state transition'
        end

        context 'when the status is checking' do
          let(:merge_status) { :checking }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is can_be_merged' do
          let(:merge_status) { :can_be_merged }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged_recheck' do
          let(:merge_status) { :cannot_be_merged_recheck }
          let(:expected_merge_status) { :cannot_be_merged_rechecking }

          include_examples 'for a valid state transition'
        end

        context 'when the status is cannot_be_merged' do
          let(:merge_status) { :cannot_be_merged }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged_rechecking' do
          let(:merge_status) { :cannot_be_merged_rechecking }

          include_examples 'for an invalid state transition'
        end
      end

      describe '#mark_as_mergeable' do
        let(:expected_merge_status) { :can_be_merged }

        def transition!
          merge_data.mark_as_mergeable!
        end

        context 'when the status is unchecked' do
          let(:merge_status) { :unchecked }

          include_examples 'for a valid state transition'
        end

        context 'when the status is checking' do
          let(:merge_status) { :checking }

          include_examples 'for a valid state transition'
        end

        context 'when the status is can_be_merged' do
          let(:merge_status) { :can_be_merged }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged_recheck' do
          let(:merge_status) { :cannot_be_merged_recheck }

          include_examples 'for a valid state transition'
        end

        context 'when the status is cannot_be_merged' do
          let(:merge_status) { :cannot_be_merged }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged_rechecking' do
          let(:merge_status) { :cannot_be_merged_rechecking }

          include_examples 'for a valid state transition'
        end
      end

      describe '#mark_as_unmergeable' do
        let(:expected_merge_status) { :cannot_be_merged }

        def transition!
          merge_data.mark_as_unmergeable!
        end

        context 'when the status is unchecked' do
          let(:merge_status) { :unchecked }

          include_examples 'for a valid state transition'
        end

        context 'when the status is checking' do
          let(:merge_status) { :checking }

          include_examples 'for a valid state transition'
        end

        context 'when the status is can_be_merged' do
          let(:merge_status) { :can_be_merged }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged_recheck' do
          let(:merge_status) { :cannot_be_merged_recheck }

          include_examples 'for a valid state transition'
        end

        context 'when the status is cannot_be_merged' do
          let(:merge_status) { :cannot_be_merged }

          include_examples 'for an invalid state transition'
        end

        context 'when the status is cannot_be_merged_rechecking' do
          let(:merge_status) { :cannot_be_merged_rechecking }

          include_examples 'for a valid state transition'
        end
      end
    end

    describe 'check_state?' do
      it 'indicates whether MR is still checking for mergeability' do
        state_machine = described_class.state_machines[:merge_status]
        check_states = [:unchecked, :cannot_be_merged_recheck, :cannot_be_merged_rechecking, :checking]

        check_states.each do |merge_status|
          expect(state_machine.check_state?(merge_status)).to be true
        end

        (state_machine.states.map(&:name) - check_states).each do |merge_status|
          expect(state_machine.check_state?(merge_status)).to be false
        end
      end
    end
  end

  describe "#public_merge_status" do
    using RSpec::Parameterized::TableSyntax

    subject(:merge_data) do
      build(:merge_requests_merge_data, merge_request: merge_request, merge_status: merge_status_id(merge_status))
    end

    where(:merge_status, :public_status) do
      :cannot_be_merged_rechecking | 'checking'
      :preparing                   | 'checking'
      :checking                    | 'checking'
      :cannot_be_merged            | 'cannot_be_merged'
    end

    with_them do
      it { expect(merge_data.public_merge_status).to eq(public_status) }
    end
  end
end

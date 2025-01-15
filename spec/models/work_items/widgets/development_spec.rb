# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Development, feature_category: :team_planning do
  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:development) }
  end

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to include(:branch_name) }
  end

  describe '#type' do
    subject { described_class.new(build_stubbed(:work_item)).type }

    it { is_expected.to eq(:development) }
  end

  describe '#closing_merge_requests' do
    let(:work_item) { build_stubbed(:work_item) }

    subject(:closing_merge_requests) { described_class.new(work_item).closing_merge_requests }

    it { is_expected.to be_a(ActiveRecord::Relation) }

    it 'returns calls the correct scope' do
      expect(work_item).to receive(:merge_requests_closing_issues)

      closing_merge_requests
    end
  end

  describe '#will_auto_close_by_merge_request' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, group: group) }
    let_it_be(:open_merge_request) { create(:merge_request, :opened, source_project: project) }
    let_it_be(:closed_merge_request) { create(:merge_request, :closed, source_project: project, target_branch: 'f2') }

    subject { described_class.new(work_item).will_auto_close_by_merge_request }

    shared_examples 'will_auto_close_by_merge_request field spec' do |all_conditions_exist|
      shared_examples 'field that depends on closing merge requests presence' do |all_conditions_exist|
        context 'when no merge request closing issue exists' do
          it { is_expected.to be_falsey }
        end

        context 'when closed merge request closing issue exists' do
          before_all do
            create(
              :merge_requests_closing_issues,
              issue_id: work_item.id,
              merge_request_id: closed_merge_request.id
            )
          end

          it { is_expected.to be_falsey }

          context 'when associated merge request is open' do
            before_all do
              create(
                :merge_requests_closing_issues,
                issue_id: work_item.id,
                merge_request_id: open_merge_request.id
              )
            end

            it { is_expected.to eq(all_conditions_exist) }
          end
        end
      end

      context 'when work item is open' do
        it_behaves_like 'field that depends on closing merge requests presence', all_conditions_exist
      end

      context 'when work item is closed' do
        before_all do
          # Reload is needed here as using before_all in shared examples doesn't play nice with let_it_be_with_reload.
          # Did this as flaky specs were detected during development
          work_item.reload.update!(state: :closed)
        end

        it_behaves_like 'field that depends on closing merge requests presence', false
      end
    end

    context 'when work item exists at the project level' do
      let_it_be_with_reload(:work_item) { create(:work_item, project: project) }

      context 'when autoclose_referenced_issues is enabled in the project' do
        it_behaves_like 'will_auto_close_by_merge_request field spec', true
      end

      context 'when autoclose_referenced_issues is disabled in the project' do
        before_all do
          project.update!(autoclose_referenced_issues: false)
        end

        it_behaves_like 'will_auto_close_by_merge_request field spec', false
      end
    end

    context 'when work item exists at the group level' do
      let_it_be_with_reload(:work_item) { create(:work_item, :group_level, namespace: group) }

      it_behaves_like 'will_auto_close_by_merge_request field spec', false
    end
  end
end

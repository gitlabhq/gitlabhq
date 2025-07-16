# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Issuable::NamespaceGetter, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let(:excluded_issuable_types) { [] }
  let(:allow_nil) { false }

  describe '#namespace_id' do
    subject(:namespace_id) do
      described_class.new(issuable, excluded_issuable_types: excluded_issuable_types, allow_nil: allow_nil).namespace_id
    end

    context 'when issuable is nil' do
      let(:issuable) { nil }

      it 'raises an error' do
        expect do
          namespace_id
        end.to raise_error(
          described_class::INVALID_ISSUABLE_ERROR,
          'NilClass is not a supported Issuable type'
        )
      end

      context 'when allow_nil is true' do
        let(:allow_nil) { true }

        it { is_expected.to be_nil }
      end
    end

    context 'when issuable is an issue' do
      let_it_be(:issuable) { create(:issue, project: project) }

      it { is_expected.to eq(project.project_namespace_id) }

      context 'when issue is a group level issue' do
        let_it_be(:issuable) { create(:issue, :group_level, namespace: group) }

        it { is_expected.to eq(group.id) }
      end

      context 'when Issue is an excluded issuable type' do
        let(:excluded_issuable_types) { [Issue] }

        it 'raises an error' do
          expect do
            namespace_id
          end.to raise_error(
            described_class::INVALID_ISSUABLE_ERROR,
            'Issue is not a supported Issuable type'
          )
        end
      end
    end

    context 'when issuable is a WorkItem' do
      let_it_be(:issuable) { create(:work_item, project: project) }

      it { is_expected.to eq(project.project_namespace_id) }

      context 'when issue is a group level issue' do
        let_it_be(:issuable) { create(:work_item, :group_level, namespace: group) }

        it { is_expected.to eq(group.id) }
      end

      context 'when WorkItem is an excluded issuable type' do
        let(:excluded_issuable_types) { [WorkItem] }

        it 'raises an error' do
          expect do
            namespace_id
          end.to raise_error(
            described_class::INVALID_ISSUABLE_ERROR,
            'WorkItem is not a supported Issuable type'
          )
        end
      end
    end

    context 'when issuable is an MergeRequest' do
      let_it_be(:issuable) { create(:merge_request, source_project: project) }

      it { is_expected.to eq(project.project_namespace_id) }

      context 'when MergeRequest is an excluded issuable type' do
        let(:excluded_issuable_types) { [MergeRequest] }

        it 'raises an error' do
          expect do
            namespace_id
          end.to raise_error(
            described_class::INVALID_ISSUABLE_ERROR,
            'MergeRequest is not a supported Issuable type'
          )
        end
      end
    end
  end
end

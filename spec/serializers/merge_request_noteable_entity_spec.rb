# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestNoteableEntity, feature_category: :code_review_workflow do
  let_it_be_with_reload(:group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- need to query from database

  let(:project) { build_stubbed(:project, namespace: group) }
  let(:user) { build_stubbed(:user) }
  let(:merge_request) { build_stubbed(:merge_request, source_project: project) }
  let(:request) { EntityRequest.new(current_user: user) }
  let(:entity) { described_class.new(merge_request, request: request).as_json }

  describe '#new_blob_path' do
    context 'when legacy diffs data is not skipped' do
      it 'exposes the path' do
        expect(entity).to have_key(:new_blob_path)
      end
    end

    context 'when legacy diffs data is skipped' do
      let(:entity) do
        described_class.new(merge_request, request: request, skip_legacy_diffs_data: true).as_json
      end

      it 'does not expose the path' do
        expect(entity).not_to have_key(:new_blob_path)
      end

      it 'does not look up the source branch' do
        expect(merge_request).not_to receive(:source_branch_exists?)

        entity
      end
    end
  end

  describe '#is_project_archived' do
    subject { entity[:is_project_archived] }

    context 'when project is not archived' do
      it { is_expected.to be(false) }
    end

    context 'when project is archived' do
      before do
        project.archived = true
      end

      it { is_expected.to be(true) }
    end

    context 'when project is in an archived group' do
      before_all do
        group.update!(archived: true)
      end

      it { is_expected.to be(true) }
    end
  end
end

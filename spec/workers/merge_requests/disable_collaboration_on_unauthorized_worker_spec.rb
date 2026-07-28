# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::DisableCollaborationOnUnauthorizedWorker, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:target_project) { create(:project, :repository, :public) }
  let_it_be(:source_project) { fork_project(target_project, nil, repository: true) }

  let_it_be_with_reload(:merge_request) do
    create(
      :merge_request,
      source_project: source_project,
      source_branch: 'fixes',
      target_project: target_project,
      allow_collaboration: true
    )
  end

  describe '#perform' do
    let(:project_id) { target_project.id }

    subject(:perform) { described_class.new.perform(project_id) }

    it 'disables collaboration on fork merge requests targeting the project' do
      expect { perform }.to change { merge_request.reload.allow_maintainer_to_push }.from(true).to(false)
    end

    context 'when the project does not exist' do
      let(:project_id) { non_existing_record_id }

      it 'does nothing' do
        expect(MergeRequest).not_to receive(:disable_collaboration_for_target_project)
        perform
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [target_project.id] }
    end
  end
end

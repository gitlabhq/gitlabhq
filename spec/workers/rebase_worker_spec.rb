# frozen_string_literal: true

require 'spec_helper'
require 'labkit/rspec/matchers'

RSpec.describe RebaseWorker, '#perform', feature_category: :source_code_management do
  include ProjectForksHelper

  describe 'ui_button_rebase UX SLI', :freeze_time do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) do
      create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master')
    end

    let_it_be(:user) { merge_request.author }

    before_all do
      project.add_maintainer(user)
    end

    context 'when the experience was started by the web UI rebase button' do
      before do
        Labkit::UserExperienceSli.start(:ui_button_rebase)
      end

      it 'resumes and completes the experience on a successful rebase', :aggregate_failures do
        expect { subject.perform(merge_request.id, user.id) }
          .to resume_user_experience(:ui_button_rebase)
          .and complete_user_experience(:ui_button_rebase)
      end

      it 'completes the experience with an error when the rebase fails', :aggregate_failures do
        allow_next_instance_of(MergeRequests::RebaseService) do |service|
          allow(service).to receive(:execute).and_return({ status: :error, message: 'Rebase failed' })
        end

        expect { subject.perform(merge_request.id, user.id) }
          .to resume_user_experience(:ui_button_rebase)
          .and complete_user_experience(:ui_button_rebase, error: true)
      end

      it 'completes the experience with an error and re-raises when the record is missing', :aggregate_failures do
        expect do
          expect { subject.perform(non_existing_record_id, user.id) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end.to complete_user_experience(:ui_button_rebase, error: true)
      end
    end

    context 'when the experience was not started (REST API or /rebase quick action)' do
      it 'does not resume the experience' do
        expect { subject.perform(merge_request.id, user.id) }
          .not_to resume_user_experience(:ui_button_rebase)
      end
    end
  end

  context 'when rebasing an MR from a fork where upstream has protected branches' do
    let(:upstream_project) { create(:project, :repository) }
    let(:forked_project) { fork_project(upstream_project, nil, repository: true) }

    let(:merge_request) do
      create(
        :merge_request,
        source_project: forked_project,
        source_branch: 'feature_conflict',
        target_project: upstream_project,
        target_branch: 'master'
      )
    end

    it 'sets the correct project for running hooks' do
      expect(MergeRequests::RebaseService)
        .to receive(:new).with(project: forked_project, current_user: merge_request.author).and_call_original

      subject.perform(merge_request.id, merge_request.author.id)
    end
  end
end

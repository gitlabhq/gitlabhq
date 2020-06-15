# frozen_string_literal: true

require 'spec_helper'

describe DiffsEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { EntityRequest.new(project: project, current_user: user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }

  let(:entity) do
    described_class.new(merge_request_diffs.first.diffs, request: request, merge_request: merge_request, merge_request_diffs: merge_request_diffs)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'contains needed attributes' do
      expect(subject).to include(
        :real_size, :size, :branch_name,
        :target_branch_name, :commit, :merge_request_diff,
        :start_version, :latest_diff, :latest_version_path,
        :added_lines, :removed_lines, :render_overflow_warning,
        :email_patch_path, :plain_diff_path, :diff_files,
        :merge_request_diffs, :definition_path_prefix
      )
    end

    context "when a commit_id is passed" do
      let(:commits) { merge_request.commits }
      let(:entity) do
        described_class.new(
          merge_request_diffs.first.diffs,
          request: request,
          merge_request: merge_request,
          merge_request_diffs: merge_request_diffs,
          commit: commit
        )
      end

      subject { entity.as_json }

      context "when the passed commit is not the first or last in the group" do
        let(:commit) { commits.third }

        it 'includes commit references for previous and next' do
          expect(subject[:commit][:next_commit_id]).to eq(commits.second.id)
          expect(subject[:commit][:prev_commit_id]).to eq(commits.fourth.id)
        end
      end

      context "when the passed commit is the first in the group" do
        let(:commit) { commits.first }

        it 'includes commit references for nil and previous commit' do
          expect(subject[:commit][:next_commit_id]).to be_nil
          expect(subject[:commit][:prev_commit_id]).to eq(commits.second.id)
        end
      end

      context "when the passed commit is the last in the group" do
        let(:commit) { commits.last }

        it 'includes commit references for the next and nil' do
          expect(subject[:commit][:next_commit_id]).to eq(commits[-2].id)
          expect(subject[:commit][:prev_commit_id]).to be_nil
        end
      end
    end

    context 'when code_navigation feature flag is disabled' do
      it 'does not include code navigation properties' do
        stub_feature_flags(code_navigation: false)

        expect(Gitlab::CodeNavigationPath).not_to receive(:new)

        expect(subject).not_to include(:definition_path_prefix)
      end
    end
  end
end

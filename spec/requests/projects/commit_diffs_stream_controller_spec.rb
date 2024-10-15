# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit diffs stream', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let(:commit_with_two_diffs) { project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e") }
  let(:offset) { 0 }

  before do
    sign_in(user)
  end

  describe 'GET diffs_stream' do
    def send_request(**extra_params)
      params = {
        namespace_id: project.namespace,
        project_id: project,
        id: commit_with_two_diffs.id,
        offset: offset
      }

      get diffs_stream_namespace_project_commit_path(params.merge(extra_params))
    end

    it 'streams the response' do
      send_request

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'includes all diffs' do
      send_request

      streamed_content = response.body

      commit_with_two_diffs.diffs.diff_files.each do |diff_file|
        expect(streamed_content).to include(diff_file.new_path)
      end
    end

    context 'when offset is given' do
      context 'when offset is 1' do
        let(:offset) { 1 }

        it 'streams diffs except the offset' do
          send_request

          diff_files = commit_with_two_diffs.diffs.diff_files.to_a
          expect(response.body).not_to include(diff_files.first.new_path)
          expect(response.body).to include(diff_files.last.new_path)
        end
      end

      context 'when offset is same as number of diffs' do
        let(:offset) { commit_with_two_diffs.diffs.size }

        it 'no diffs are streamed' do
          send_request

          expect(response.body).to be_empty
        end
      end
    end

    context 'when an exception occurs' do
      before do
        allow(::RapidDiffs::DiffFileComponent)
          .to receive(:new).and_raise(StandardError.new('something went wrong'))
      end

      it 'prints out error message' do
        send_request

        expect(response.body).to include('something went wrong')
      end
    end

    context 'when the rapid_diffs feature flag is disabled' do
      before do
        stub_feature_flags(rapid_diffs: false)
      end

      it 'returns a 404 status' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end

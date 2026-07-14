# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit diffs stream', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let(:commit_with_two_diffs) { project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e") }
  let(:offset) { 0 }
  let(:diff_files) { commit_with_two_diffs.diffs.diff_files }

  before do
    sign_in(user)
  end

  describe 'GET diffs_stream' do
    def go(**extra_params)
      params = {
        namespace_id: project.namespace,
        project_id: project,
        id: commit_with_two_diffs.id,
        offset: offset
      }

      get diffs_stream_namespace_project_commit_path(params.merge(extra_params))
    end

    it 'includes all diffs' do
      go

      streamed_content = response.body

      commit_with_two_diffs.diffs.diff_files.each do |diff_file|
        expect(streamed_content).to include(diff_file.new_path)
      end
    end

    include_examples 'diffs stream tests'

    include_examples 'with diffs_blobs param'

    context 'with environment' do
      let(:environment) { create(:environment, project: project, external_url: 'https://example.com') }

      before do
        allow_next_instance_of(Environments::EnvironmentsByDeploymentsFinder) do |finder|
          allow(finder).to receive(:execute).and_return([environment])
        end

        allow(project).to receive(:public_path_for_source_path).and_return('public/file.html')
      end

      it 'includes environment link in response' do
        go

        expect(response.body).to include(environment.formatted_external_url)
      end
    end

    context 'without environment' do
      it 'does not include environment link in response' do
        go

        expect(response.body).not_to include('View on')
      end
    end
  end
end

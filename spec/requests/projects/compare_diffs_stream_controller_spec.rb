# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Compare diffs stream', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let(:whitespace) { nil }
  let(:straight) { true }
  let(:page) { nil }
  let(:from_project_id) { nil }
  let(:offset) { 0 }
  let(:start_ref) { '08f22f25' }
  let(:target_ref) { 'master' }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      from_project_id: from_project_id,
      from: start_ref,
      to: target_ref,
      w: whitespace,
      page: page,
      straight: straight,
      offset: offset
    }
  end

  let(:raw_compare) do
    project.repository.compare_source_branch(start_ref, project.repository, target_ref, straight: straight)
  end

  let(:compare) { Compare.new(raw_compare, project, base_sha: nil, straight: straight) }
  let(:diff_files) { compare.diffs.diff_files.to_a }

  describe 'GET diffs_stream' do
    def go(**extra_params)
      get diffs_stream_namespace_project_compare_index_path(request_params.merge(extra_params))
    end

    it 'includes all diffs' do
      go

      streamed_content = response.body

      diff_files.each do |diff_file|
        expect(streamed_content).to include(diff_file.new_path)
      end
    end

    include_examples 'diffs stream tests'

    include_examples 'with diffs_blobs param'

    context 'with environment' do
      let(:environment) { create(:environment, project: project, external_url: 'https://example.com') }

      before do
        create(:deployment, :success, environment: environment, project: project, sha: compare.head_commit_sha)

        allow_next_instance_of(Environments::EnvironmentsByDeploymentsFinder) do |finder|
          allow(finder).to receive(:execute).and_return([environment])
        end

        allow(project).to receive(:public_path_for_source_path).and_return('public/file.html')
      end

      it 'includes environment link in response' do
        go

        expect(response.body).to include('View on')
        expect(response.body).to include(environment.formatted_external_url)
      end
    end

    context 'without environment' do
      before do
        create(:deployment, :success, environment: create(:environment, project: project),
          project: project, sha: compare.head_commit_sha)

        allow_next_instance_of(Environments::EnvironmentsByDeploymentsFinder) do |finder|
          allow(finder).to receive(:execute).and_return([])
        end
      end

      it 'does not include environment link in response' do
        go

        expect(response.body).not_to include('View on')
      end
    end
  end
end

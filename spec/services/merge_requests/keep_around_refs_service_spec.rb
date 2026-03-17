# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::KeepAroundRefsService, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:merge_request_diff) { merge_request.merge_request_diff }

  let(:start_commit_sha) { merge_request_diff.start_commit_sha }
  let(:head_commit_sha) { merge_request_diff.head_commit_sha }
  let(:source) { 'MergeRequestDiff' }

  describe '#execute' do
    context 'with a single project' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [start_commit_sha, head_commit_sha],
          source: source
        )
      end

      it 'calls keep_around on the repository with the correct SHAs and source' do
        repo = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around)

        service.execute

        expect(repo).to have_received(:keep_around).with(
          start_commit_sha,
          head_commit_sha,
          source: 'MergeRequestDiff'
        ).once
      end
    end

    context 'with two different projects' do
      let_it_be(:source_project) { fork_project(project, nil, repository: true) }

      subject(:service) do
        described_class.new(
          project_ids: [project.id, source_project.id],
          shas: [start_commit_sha, head_commit_sha],
          source: source
        )
      end

      it 'calls keep_around on both repositories' do
        repo1 = instance_double(Repository)
        repo2 = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id, source_project.id]).and_return([project, source_project])
        allow(project).to receive(:repository).and_return(repo1)
        allow(source_project).to receive(:repository).and_return(repo2)
        allow(repo1).to receive(:keep_around)
        allow(repo2).to receive(:keep_around)

        service.execute

        expect(repo1).to have_received(:keep_around).with(
          start_commit_sha, head_commit_sha, source: 'MergeRequestDiff'
        )
        expect(repo2).to have_received(:keep_around).with(
          start_commit_sha, head_commit_sha, source: 'MergeRequestDiff'
        )
      end
    end

    context 'with non-existing project ID' do
      subject(:service) do
        described_class.new(
          project_ids: [non_existing_record_id],
          shas: [start_commit_sha],
          source: source
        )
      end

      it 'does not raise an error' do
        expect { service.execute }.not_to raise_error
      end
    end

    context 'with empty shas' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [],
          source: source
        )
      end

      it 'does not query for projects' do
        expect(Project).not_to receive(:id_in)

        service.execute
      end
    end

    context 'when source is MergeRequest' do
      subject(:service) do
        described_class.new(
          project_ids: [project.id],
          shas: [start_commit_sha],
          source: 'MergeRequest'
        )
      end

      it 'passes the correct source' do
        repo = instance_double(Repository)
        allow(Project).to receive(:id_in).with([project.id]).and_return([project])
        allow(project).to receive(:repository).and_return(repo)
        allow(repo).to receive(:keep_around)

        service.execute

        expect(repo).to have_received(:keep_around).with(
          start_commit_sha,
          source: 'MergeRequest'
        )
      end
    end
  end
end

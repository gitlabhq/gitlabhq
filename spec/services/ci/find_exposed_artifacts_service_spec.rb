# frozen_string_literal: true

require 'spec_helper'

describe Ci::FindExposedArtifactsService do
  include Gitlab::Routing

  let(:metadata) do
    Gitlab::Ci::Build::Artifacts::Metadata
      .new(metadata_file_stream, path, { recursive: true })
  end

  let(:metadata_file_stream) do
    File.open(Rails.root + 'spec/fixtures/ci_build_artifacts_metadata.gz')
  end

  let_it_be(:project) { create(:project) }
  let(:user) { nil }

  after do
    metadata_file_stream&.close
  end

  def create_job_with_artifacts(options)
    create(:ci_build, pipeline: pipeline, options: options).tap do |job|
      create(:ci_job_artifact, :metadata, job: job)
    end
  end

  describe '#for_pipeline' do
    shared_examples 'finds a single match' do
      it 'returns the artifact with exact location' do
        expect(subject).to eq([{
          text: 'Exposed artifact',
          url: file_project_job_artifacts_path(project, job, 'other_artifacts_0.1.2/doc_sample.txt'),
          job_name: job.name,
          job_path: project_job_path(project, job)
        }])
      end
    end

    shared_examples 'finds multiple matches' do
      it 'returns the path to the artifacts browser' do
        expect(subject).to eq([{
          text: 'Exposed artifact',
          url: browse_project_job_artifacts_path(project, job),
          job_name: job.name,
          job_path: project_job_path(project, job)
        }])
      end
    end

    shared_examples 'does not find any matches' do
      it 'returns empty array' do
        expect(subject).to eq []
      end
    end

    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    subject { described_class.new(project, user).for_pipeline(pipeline) }

    context 'with jobs having no exposed artifacts' do
      let!(:job) do
        create_job_with_artifacts(artifacts: {
          paths: ['other_artifacts_0.1.2/doc_sample.txt', 'something-else.html']
        })
      end

      it_behaves_like 'does not find any matches'
    end

    context 'with jobs having no artifacts (metadata)' do
      let!(:job) do
        create(:ci_build, pipeline: pipeline, options: {
          artifacts: {
            expose_as: 'Exposed artifact',
            paths: ['other_artifacts_0.1.2/doc_sample.txt', 'something-else.html']
          }
        })
      end

      it_behaves_like 'does not find any matches'
    end

    context 'with jobs having at most 1 matching exposed artifact' do
      let!(:job) do
        create_job_with_artifacts(artifacts: {
          expose_as: 'Exposed artifact',
          paths: ['other_artifacts_0.1.2/doc_sample.txt', 'something-else.html']
        })
      end

      it_behaves_like 'finds a single match'
    end

    context 'with jobs having more than 1 matching exposed artifacts' do
      let!(:job) do
        create_job_with_artifacts(artifacts: {
          expose_as: 'Exposed artifact',
          paths: [
            'ci_artifacts.txt',
            'other_artifacts_0.1.2/doc_sample.txt',
            'something-else.html'
          ]
        })
      end

      it_behaves_like 'finds multiple matches'
    end

    context 'with jobs having more than 1 matching exposed artifacts inside a directory' do
      let!(:job) do
        create_job_with_artifacts(artifacts: {
          expose_as: 'Exposed artifact',
          paths: ['tests_encoding/']
        })
      end

      it_behaves_like 'finds multiple matches'
    end

    context 'with jobs having paths with glob expression' do
      let!(:job) do
        create_job_with_artifacts(artifacts: {
          expose_as: 'Exposed artifact',
          paths: ['other_artifacts_0.1.2/doc_sample.txt', 'tests_encoding/*.*']
        })
      end

      it_behaves_like 'finds a single match' # because those with * are ignored
    end

    context 'limiting results' do
      let!(:job1) do
        create_job_with_artifacts(artifacts: {
          expose_as: 'artifact 1',
          paths: ['ci_artifacts.txt']
        })
      end

      let!(:job2) do
        create_job_with_artifacts(artifacts: {
          expose_as: 'artifact 2',
          paths: ['tests_encoding/']
        })
      end

      let!(:job3) do
        create_job_with_artifacts(artifacts: {
          expose_as: 'should not be exposed',
          paths: ['other_artifacts_0.1.2/doc_sample.txt']
        })
      end

      subject { described_class.new(project, user).for_pipeline(pipeline, limit: 2) }

      it 'returns first 2 results' do
        expect(subject).to eq([
          {
            text: 'artifact 1',
            url: file_project_job_artifacts_path(project, job1, 'ci_artifacts.txt'),
            job_name: job1.name,
            job_path: project_job_path(project, job1)
          },
          {
            text: 'artifact 2',
            url: browse_project_job_artifacts_path(project, job2),
            job_name: job2.name,
            job_path: project_job_path(project, job2)
          }
        ])
      end
    end
  end
end

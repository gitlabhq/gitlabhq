# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::CoverageReportGenerator,
  factory_default: :keep,
  feature_category: :code_testing do
  let_it_be(:project) { create_default(:project, :repository).freeze }
  let_it_be(:jacoco_filenames) { %w[src/main/org/acme/AnotherResource.java src/main/org/acme/ExampleResource.java] }
  let_it_be(:source_branch) { 'jvm_branch' }
  let(:merge_request) { create(:merge_request, source_branch: source_branch) }
  let(:pipeline) { create(:ci_pipeline, :success, head_pipeline_of: merge_request) }

  before_all do
    project.repository.add_branch(project.creator, source_branch, 'master')
    jacoco_filenames.each do |filename|
      project.repository.create_file(
        project.creator,
        filename,
        'Sample content',
        message: "Add #{filename}",
        branch_name: source_branch
      )
    end
  end

  describe '#report' do
    subject { described_class.new(pipeline).report }

    shared_examples 'having a coverage report' do
      it 'returns coverage reports with collected data' do
        expected_files = [
          "auth/token.go",
          "auth/rpccredentials.go",
          "app/controllers/abuse_reports_controller.rb",
          "src/main/org/acme/AnotherResource.java",
          "src/main/org/acme/ExampleResource.java"
        ]

        expect(subject.files.keys).to match_array(expected_files)
      end
    end

    context 'when pipeline has multiple builds with coverage reports' do
      let!(:build_rspec) { create(:ci_build, :success, name: 'rspec', pipeline: pipeline) }
      let!(:build_golang) { create(:ci_build, :success, name: 'golang', pipeline: pipeline) }
      let!(:build_jvm) { create(:ci_build, :success, name: 'jvm', pipeline: pipeline) }

      before do
        create(:ci_job_artifact, :jacoco, job: build_jvm)
        create(:ci_job_artifact, :cobertura, job: build_rspec)
        create(:ci_job_artifact, :coverage_gocov_xml, job: build_golang)
      end

      it_behaves_like 'having a coverage report'

      context 'and it is a child pipeline' do
        let!(:pipeline) { create(:ci_pipeline, :success, child_of: build(:ci_pipeline)) }

        it 'returns empty coverage report' do
          expect(subject).to be_empty
        end
      end

      context 'when there are multiple merge requests for the same source branch' do
        let(:other_merge_request) { create(:merge_request, source_branch: source_branch) }

        it_behaves_like 'having a coverage report'
      end

      context 'when the pipeline is not the head of any merge request' do
        let(:pipeline) { create(:ci_pipeline, :success) }

        it 'returns empty coverage report' do
          expect(subject).to be_empty
        end
      end
    end

    context 'when builds are retried' do
      let!(:build_rspec) { create(:ci_build, :success, name: 'rspec', retried: true, pipeline: pipeline) }
      let!(:build_golang) { create(:ci_build, :success, name: 'golang', retried: true, pipeline: pipeline) }
      let!(:build_jvm) { create(:ci_build, :success, name: 'jvm', retried: true, pipeline: pipeline) }

      before do
        create(:ci_job_artifact, :jacoco, job: build_jvm)
        create(:ci_job_artifact, :cobertura, job: build_rspec)
        create(:ci_job_artifact, :coverage_gocov_xml, job: build_golang)
      end

      it 'does not take retried builds into account' do
        expect(subject).to be_empty
      end
    end

    context 'when pipeline does not have any builds with coverage reports' do
      it 'returns empty coverage reports' do
        expect(subject).to be_empty
      end
    end

    context 'when pipeline has child pipeline with builds that have coverage reports' do
      let!(:child_pipeline) { create(:ci_pipeline, :success, child_of: pipeline) }

      let!(:build_rspec) { create(:ci_build, :success, name: 'rspec', pipeline: child_pipeline) }
      let!(:build_golang) { create(:ci_build, :success, name: 'golang', pipeline: child_pipeline) }
      let!(:build_jvm) { create(:ci_build, :success, name: 'jvm', pipeline: child_pipeline) }

      before do
        create(:ci_job_artifact, :cobertura, job: build_rspec)
        create(:ci_job_artifact, :coverage_gocov_xml, job: build_golang)
        create(:ci_job_artifact, :jacoco, job: build_jvm)
      end

      it_behaves_like 'having a coverage report'
    end

    context 'when both parent and child pipeline have builds with coverage reports' do
      let!(:child_pipeline) { create(:ci_pipeline, :success, child_of: pipeline) }

      let!(:build_rspec) { create(:ci_build, :success, name: 'rspec', pipeline: pipeline) }
      let!(:build_golang) { create(:ci_build, :success, name: 'golang', pipeline: child_pipeline) }
      let!(:build_jvm) { create(:ci_build, :success, name: 'jvm', pipeline: child_pipeline) }

      before do
        create(:ci_job_artifact, :cobertura, job: build_rspec)
        create(:ci_job_artifact, :coverage_gocov_xml, job: build_golang)
        create(:ci_job_artifact, :jacoco, job: build_jvm)
      end

      it_behaves_like 'having a coverage report'
    end
  end
end

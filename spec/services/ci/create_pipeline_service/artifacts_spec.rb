# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:ref) { 'refs/heads/master' }
  let(:source) { :push }

  let(:service) { described_class.new(project, user, { ref: ref }) }
  let(:pipeline) { service.execute(source).payload }

  describe 'artifacts:' do
    before do
      stub_ci_pipeline_yaml_file(config)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |instance|
        allow(instance).to receive(:perform).and_return(true)
      end
    end

    describe 'reports:' do
      context 'with valid config' do
        let(:config) do
          <<~YAML
          test-job:
            script: "echo 'hello world' > cobertura.xml"
            artifacts:
              reports:
                coverage_report:
                  coverage_format: 'cobertura'
                  path: 'cobertura.xml'

          dependency-scanning-job:
            script: "echo 'hello world' > gl-dependency-scanning-report.json"
            artifacts:
              reports:
                dependency_scanning: 'gl-dependency-scanning-report.json'
          YAML
        end

        it 'creates pipeline with builds' do
          expect(pipeline).to be_persisted
          expect(pipeline).not_to have_yaml_errors
          expect(pipeline.builds.pluck(:name)).to contain_exactly('test-job', 'dependency-scanning-job')
        end
      end

      context 'with invalid config' do
        let(:config) do
          <<~YAML
          test-job:
            script: "echo 'hello world' > cobertura.xml"
            artifacts:
              reports:
                foo: 'bar'
          YAML
        end

        it 'creates pipeline with yaml errors' do
          expect(pipeline).to be_persisted
          expect(pipeline).to have_yaml_errors
        end
      end
    end
  end
end

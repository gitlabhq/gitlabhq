# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreatePipelineService do
  context 'needs' do
    let_it_be(:user)    { create(:admin) }
    let_it_be(:project) { create(:project, :repository, creator: user) }

    let(:ref)      { 'refs/heads/master' }
    let(:source)   { :push }
    let(:service)  { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { service.execute(source) }

    before do
      stub_ci_pipeline_yaml_file(config)
    end

    context 'with a valid config' do
      let(:config) do
        <<~YAML
          build_a:
            stage: build
            script:
              - make
            artifacts:
              paths:
                - binaries/
          build_b:
            stage: build
            script:
              - make
            artifacts:
              paths:
                - other_binaries/
          build_c:
            stage: build
            script:
              - make
          build_d:
            stage: build
            script:
              - make
            parallel: 3

          test_a:
            stage: test
            script:
              - ls
            needs:
              - build_a
              - job: build_b
                artifacts: true
              - job: build_c
                artifacts: false
            dependencies:
              - build_a

          test_b:
            stage: test
            script:
              - ls
            parallel: 2
            needs:
              - build_a
              - job: build_b
                artifacts: true
              - job: build_d
                artifacts: false

          test_c:
            stage: test
            script:
              - ls
            needs:
              - build_a
              - job: build_b
              - job: build_c
                artifacts: true
        YAML
      end

      let(:test_a_build) { pipeline.builds.find_by!(name: 'test_a') }

      it 'creates a pipeline with builds' do
        expected_builds = [
          'build_a', 'build_b', 'build_c', 'build_d 1/3', 'build_d 2/3',
          'build_d 3/3', 'test_a', 'test_b 1/2', 'test_b 2/2', 'test_c'
        ]

        expect(pipeline).to be_persisted
        expect(pipeline.builds.pluck(:name)).to contain_exactly(*expected_builds)
      end

      it 'saves needs' do
        expect(test_a_build.needs.map(&:attributes))
          .to contain_exactly(
            a_hash_including('name' => 'build_a', 'artifacts' => true),
            a_hash_including('name' => 'build_b', 'artifacts' => true),
            a_hash_including('name' => 'build_c', 'artifacts' => false)
          )
      end

      it 'saves dependencies' do
        expect(test_a_build.options)
          .to match(a_hash_including('dependencies' => ['build_a']))
      end

      it 'artifacts default to true' do
        test_job = pipeline.builds.find_by!(name: 'test_c')

        expect(test_job.needs.map(&:attributes))
          .to contain_exactly(
            a_hash_including('name' => 'build_a', 'artifacts' => true),
            a_hash_including('name' => 'build_b', 'artifacts' => true),
            a_hash_including('name' => 'build_c', 'artifacts' => true)
          )
      end

      it 'saves parallel jobs' do
        ['1/2', '2/2'].each do |part|
          test_job = pipeline.builds.find_by(name: "test_b #{part}")

          expect(test_job.needs.map(&:attributes))
            .to contain_exactly(
              a_hash_including('name' => 'build_a',     'artifacts' => true),
              a_hash_including('name' => 'build_b',     'artifacts' => true),
              a_hash_including('name' => 'build_d 1/3', 'artifacts' => false),
              a_hash_including('name' => 'build_d 2/3', 'artifacts' => false),
              a_hash_including('name' => 'build_d 3/3', 'artifacts' => false)
            )
        end
      end
    end

    context 'with an invalid config' do
      let(:config) do
        <<~YAML
          build_a:
            stage: build
            script:
              - make
            artifacts:
              paths:
                - binaries/

          build_b:
            stage: build
            script:
              - make
            artifacts:
              paths:
                - other_binaries/

          test_a:
            stage: test
            script:
              - ls
            needs:
              - build_a
              - job: build_b
                artifacts: string
        YAML
      end

      it { expect(pipeline).to be_persisted }
      it { expect(pipeline.builds.any?).to be_falsey }

      it 'assigns an error to the pipeline' do
        expect(pipeline.yaml_errors)
          .to eq('jobs:test_a:needs:need artifacts should be a boolean value')
      end
    end
  end
end

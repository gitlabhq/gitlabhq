# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreatePipelineService, '#execute' do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }
  let(:ref_name) { 'master' }

  let(:service) do
    params = { ref: ref_name,
               before: '00000000',
               after: project.commit.id,
               commits: [{ message: 'some commit' }] }

    described_class.new(project, user, params)
  end

  before do
    project.add_developer(user)
    stub_ci_pipeline_to_return_yaml_file
  end

  describe 'child pipeline triggers' do
    before do
      stub_ci_pipeline_yaml_file <<~YAML
        test:
          script: rspec

        deploy:
          variables:
            CROSS: downstream
          stage: deploy
          trigger:
            include:
              - local: path/to/child.yml
      YAML
    end

    it 'creates bridge jobs correctly' do
      pipeline = create_pipeline!

      test = pipeline.statuses.find_by(name: 'test')
      bridge = pipeline.statuses.find_by(name: 'deploy')

      expect(pipeline).to be_persisted
      expect(test).to be_a Ci::Build
      expect(bridge).to be_a Ci::Bridge
      expect(bridge.stage).to eq 'deploy'
      expect(pipeline.statuses).to match_array [test, bridge]
      expect(bridge.options).to eq(
        'trigger' => { 'include' => [{ 'local' => 'path/to/child.yml' }] }
      )
      expect(bridge.yaml_variables)
        .to include(key: 'CROSS', value: 'downstream', public: true)
    end
  end

  describe 'child pipeline triggers' do
    context 'when YAML is valid' do
      before do
        stub_ci_pipeline_yaml_file <<~YAML
          test:
            script: rspec

          deploy:
            variables:
              CROSS: downstream
            stage: deploy
            trigger:
              include:
                - local: path/to/child.yml
        YAML
      end

      it 'creates bridge jobs correctly' do
        pipeline = create_pipeline!

        test = pipeline.statuses.find_by(name: 'test')
        bridge = pipeline.statuses.find_by(name: 'deploy')

        expect(pipeline).to be_persisted
        expect(test).to be_a Ci::Build
        expect(bridge).to be_a Ci::Bridge
        expect(bridge.stage).to eq 'deploy'
        expect(pipeline.statuses).to match_array [test, bridge]
        expect(bridge.options).to eq(
          'trigger' => { 'include' => [{ 'local' => 'path/to/child.yml' }] }
        )
        expect(bridge.yaml_variables)
          .to include(key: 'CROSS', value: 'downstream', public: true)
      end
    end

    context 'when YAML is invalid' do
      let(:config) do
        {
          test: { script: 'rspec' },
          deploy: {
            trigger: { include: included_files }
          }
        }
      end

      let(:included_files) do
        Array.new(include_max_size + 1) do |index|
          { local: "file#{index}.yml" }
        end
      end

      let(:include_max_size) do
        Gitlab::Ci::Config::Entry::Trigger::ComplexTrigger::SameProjectTrigger::INCLUDE_MAX_SIZE
      end

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(config))
      end

      it 'returns errors' do
        pipeline = create_pipeline!

        expect(pipeline.errors.full_messages.first).to match(/trigger:include config is too long/)
        expect(pipeline.failure_reason).to eq 'config_error'
        expect(pipeline).to be_persisted
        expect(pipeline.status).to eq 'failed'
      end
    end
  end

  def create_pipeline!
    service.execute(:push)
  end
end

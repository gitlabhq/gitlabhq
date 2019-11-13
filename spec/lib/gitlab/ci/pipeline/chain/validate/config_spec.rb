# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Validate::Config do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      save_incompleted: true)
  end

  let(:pipeline) do
    build(:ci_pipeline, project: project)
  end

  let!(:step) { described_class.new(pipeline, command) }

  subject { step.perform! }

  context 'when pipeline has no YAML configuration' do
    let(:pipeline) do
      build_stubbed(:ci_pipeline, project: project)
    end

    it 'appends errors about missing configuration' do
      subject

      expect(pipeline.errors.to_a)
        .to include 'Missing .gitlab-ci.yml file'
    end

    it 'breaks the chain' do
      subject

      expect(step.break?).to be true
    end
  end

  context 'when YAML configuration contains errors' do
    before do
      stub_ci_pipeline_yaml_file('invalid YAML')
      subject
    end

    it 'appends errors about YAML errors' do
      expect(pipeline.errors.to_a)
        .to include 'Invalid configuration format'
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    context 'when saving incomplete pipeline is allowed' do
      let(:command) do
        double('command', project: project,
                          current_user: user,
                          save_incompleted: true)
      end

      it 'fails the pipeline' do
        subject

        expect(pipeline.reload).to be_failed
      end

      it 'sets a config error failure reason' do
        subject

        expect(pipeline.reload.config_error?).to eq true
      end
    end

    context 'when saving incomplete pipeline is not allowed' do
      let(:command) do
        double('command', project: project,
                          current_user: user,
                          save_incompleted: false)
      end

      it 'does not drop pipeline' do
        subject

        expect(pipeline).not_to be_failed
        expect(pipeline).not_to be_persisted
      end
    end
  end

  context 'when pipeline contains configuration validation errors' do
    before do
      stub_ci_pipeline_yaml_file(YAML.dump({
        rspec: {
          before_script: 10,
          script: 'ls -al'
        }
      }))

      subject
    end

    it 'appends configuration validation errors to pipeline errors' do
      expect(pipeline.errors.to_a)
        .to include "jobs:rspec:before_script config should be an array containing strings and arrays of strings"
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end
  end

  context 'when pipeline is correct and complete' do
    before do
      stub_ci_pipeline_yaml_file(YAML.dump({
        rspec: {
          script: 'rspec'
        }
      }))
      subject
    end

    it 'does not invalidate the pipeline' do
      expect(pipeline).to be_valid
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end
  end

  context 'when pipeline source is merge request' do
    before do
      stub_ci_pipeline_yaml_file(YAML.dump(config))
      subject
    end

    let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }

    let(:merge_request_pipeline) do
      build(:ci_pipeline, source: :merge_request_event, project: project)
    end

    let(:chain) { described_class.new(merge_request_pipeline, command).tap(&:perform!) }

    context "when config contains 'merge_requests' keyword" do
      let(:config) { { rspec: { script: 'echo', only: ['merge_requests'] } } }

      it 'does not break the chain' do
        expect(chain).not_to be_break
      end
    end

    context "when config contains 'merge_request' keyword" do
      let(:config) { { rspec: { script: 'echo', only: ['merge_request'] } } }

      it 'does not break the chain' do
        expect(chain).not_to be_break
      end
    end
  end
end

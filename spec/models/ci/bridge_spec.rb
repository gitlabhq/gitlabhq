# frozen_string_literal: true

require 'spec_helper'

describe Ci::Bridge do
  let_it_be(:project) { create(:project) }
  let_it_be(:target_project) { create(:project, name: 'project', namespace: create(:namespace, name: 'my')) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) do
    create(:ci_bridge, :variables, status: :created,
                                   options: options,
                                   pipeline: pipeline)
  end

  let(:options) do
    { trigger: { project: 'my/project', branch: 'master' } }
  end

  it 'has many sourced pipelines' do
    expect(bridge).to have_many(:sourced_pipelines)
  end

  describe '#tags' do
    it 'only has a bridge tag' do
      expect(bridge.tags).to eq [:bridge]
    end
  end

  describe '#detailed_status' do
    let(:user) { create(:user) }
    let(:status) { bridge.detailed_status(user) }

    it 'returns detailed status object' do
      expect(status).to be_a Gitlab::Ci::Status::Created
    end
  end

  describe '#scoped_variables_hash' do
    it 'returns a hash representing variables' do
      variables = %w[
        CI_JOB_NAME CI_JOB_STAGE CI_COMMIT_SHA CI_COMMIT_SHORT_SHA
        CI_COMMIT_BEFORE_SHA CI_COMMIT_REF_NAME CI_COMMIT_REF_SLUG
        CI_PROJECT_ID CI_PROJECT_NAME CI_PROJECT_PATH
        CI_PROJECT_PATH_SLUG CI_PROJECT_NAMESPACE CI_PIPELINE_IID
        CI_CONFIG_PATH CI_PIPELINE_SOURCE CI_COMMIT_MESSAGE
        CI_COMMIT_TITLE CI_COMMIT_DESCRIPTION CI_COMMIT_REF_PROTECTED
      ]

      expect(bridge.scoped_variables_hash.keys).to include(*variables)
    end
  end

  describe 'state machine transitions' do
    context 'when bridge points towards downstream' do
      it 'schedules downstream pipeline creation' do
        expect(bridge).to receive(:schedule_downstream_pipeline!)

        bridge.enqueue!
      end
    end
  end

  describe 'state machine transitions' do
    context 'when bridge points towards downstream' do
      it 'schedules downstream pipeline creation' do
        expect(bridge).to receive(:schedule_downstream_pipeline!)

        bridge.enqueue!
      end
    end
  end

  describe 'state machine transitions' do
    context 'when bridge points towards downstream' do
      it 'schedules downstream pipeline creation' do
        expect(bridge).to receive(:schedule_downstream_pipeline!)

        bridge.enqueue!
      end
    end
  end

  describe '#inherit_status_from_downstream!' do
    let(:downstream_pipeline) { build(:ci_pipeline, status: downstream_status) }

    before do
      bridge.status = 'pending'
      create(:ci_sources_pipeline, pipeline: downstream_pipeline, source_job: bridge)
    end

    subject { bridge.inherit_status_from_downstream!(downstream_pipeline) }

    context 'when status is not supported' do
      (::Ci::Pipeline::AVAILABLE_STATUSES - ::Ci::Pipeline::COMPLETED_STATUSES).map(&:to_s).each do |status|
        context "when status is #{status}" do
          let(:downstream_status) { status }

          it 'returns false' do
            expect(subject).to eq(false)
          end

          it 'does not change the bridge status' do
            expect { subject }.not_to change { bridge.status }.from('pending')
          end
        end
      end
    end

    context 'when status is supported' do
      using RSpec::Parameterized::TableSyntax

      where(:downstream_status, :upstream_status) do
        [
          %w[success success],
          *::Ci::Pipeline.completed_statuses.without(:success).map { |status| [status.to_s, 'failed'] }
        ]
      end

      with_them do
        it 'inherits the downstream status' do
          expect { subject }.to change { bridge.status }.from('pending').to(upstream_status)
        end
      end
    end
  end

  describe '#dependent?' do
    subject { bridge.dependent? }

    context 'when bridge has strategy depend' do
      let(:options) { { trigger: { project: 'my/project', strategy: 'depend' } } }

      it { is_expected.to be true }
    end

    context 'when bridge does not have strategy depend' do
      it { is_expected.to be false }
    end
  end

  describe '#yaml_variables' do
    it 'returns YAML variables' do
      expect(bridge.yaml_variables)
        .to include(key: 'BRIDGE', value: 'cross', public: true)
    end
  end

  describe '#downstream_variables' do
    it 'returns variables that are going to be passed downstream' do
      expect(bridge.downstream_variables)
        .to include(key: 'BRIDGE', value: 'cross')
    end

    context 'when using variables interpolation' do
      let(:yaml_variables) do
        [
          {
            key: 'EXPANDED',
            value: '$BRIDGE-bridge',
            public: true
          },
          {
            key: 'UPSTREAM_CI_PIPELINE_ID',
            value: '$CI_PIPELINE_ID',
            public: true
          },
          {
            key: 'UPSTREAM_CI_PIPELINE_URL',
            value: '$CI_PIPELINE_URL',
            public: true
          }
        ]
      end

      before do
        bridge.yaml_variables.concat(yaml_variables)
      end

      it 'correctly expands variables with interpolation' do
        expanded_values = pipeline
          .persisted_variables
          .to_hash
          .transform_keys { |key| "UPSTREAM_#{key}" }
          .map { |key, value| { key: key, value: value } }
          .push(key: 'EXPANDED', value: 'cross-bridge')

        expect(bridge.downstream_variables)
          .to match(a_collection_including(*expanded_values))
      end
    end

    context 'when recursive interpolation has been used' do
      before do
        bridge.yaml_variables << { key: 'EXPANDED', value: '$EXPANDED', public: true }
      end

      it 'does not expand variable recursively' do
        expect(bridge.downstream_variables)
          .to include(key: 'EXPANDED', value: '$EXPANDED')
      end
    end
  end

  describe 'metadata support' do
    it 'reads YAML variables from metadata' do
      expect(bridge.yaml_variables).not_to be_empty
      expect(bridge.metadata).to be_a Ci::BuildMetadata
      expect(bridge.read_attribute(:yaml_variables)).to be_nil
      expect(bridge.metadata.config_variables).to be bridge.yaml_variables
    end

    it 'reads options from metadata' do
      expect(bridge.options).not_to be_empty
      expect(bridge.metadata).to be_a Ci::BuildMetadata
      expect(bridge.read_attribute(:options)).to be_nil
      expect(bridge.metadata.config_options).to be bridge.options
    end
  end

  describe '#triggers_child_pipeline?' do
    subject { bridge.triggers_child_pipeline? }

    context 'when bridge defines a downstream YAML' do
      let(:options) do
        {
          trigger: {
            include: 'path/to/child.yml'
          }
        }
      end

      it { is_expected.to be_truthy }
    end

    context 'when bridge does not define a downstream YAML' do
      let(:options) do
        {
          trigger: {
            project: project.full_path
          }
        }
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#yaml_for_downstream' do
    subject { bridge.yaml_for_downstream }

    context 'when bridge defines a downstream YAML' do
      let(:options) do
        {
          trigger: {
            include: 'path/to/child.yml'
          }
        }
      end

      let(:yaml) do
        <<~EOY
          ---
          include: path/to/child.yml
        EOY
      end

      it { is_expected.to eq yaml }
    end

    context 'when bridge does not define a downstream YAML' do
      let(:options) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe '#target_ref' do
    context 'when trigger is defined' do
      it 'returns a ref name' do
        expect(bridge.target_ref).to eq 'master'
      end

      context 'when using variable expansion' do
        let(:options) { { trigger: { project: 'my/project', branch: '$BRIDGE-master' } } }

        it 'correctly expands variables' do
          expect(bridge.target_ref).to eq('cross-master')
        end
      end
    end

    context 'when trigger does not have project defined' do
      let(:options) { nil }

      it 'returns nil' do
        expect(bridge.target_ref).to be_nil
      end
    end
  end
end

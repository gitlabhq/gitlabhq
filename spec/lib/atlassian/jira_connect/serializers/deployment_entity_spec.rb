# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::DeploymentEntity do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:project) { create_default(:project, :repository) }
  let_it_be(:environment) { create(:environment, name: 'prod', project: project) }
  let_it_be_with_reload(:deployment) { create(:deployment, environment: environment) }

  subject { described_class.represent(deployment) }

  context 'when the deployment does not belong to any Jira issue' do
    describe '#issue_keys' do
      it 'is empty' do
        expect(subject.issue_keys).to be_empty
      end
    end

    describe '#to_json' do
      it 'can encode the object' do
        expect(subject.to_json).to be_valid_json
      end

      it 'is invalid, since it has no issue keys' do
        expect(subject.to_json).not_to match_schema(Atlassian::Schemata.deployment_info)
      end
    end
  end

  context 'this is an external deployment' do
    before do
      deployment.update!(deployable: nil)
    end

    it 'does not raise errors when serializing' do
      expect { subject.to_json }.not_to raise_error
    end

    it 'returns an empty list of issue keys' do
      expect(subject.issue_keys).to be_empty
    end
  end

  describe 'environment type' do
    using RSpec::Parameterized::TableSyntax

    where(:env_name, :env_type) do
      'prod'           | 'production'
      'test'           | 'testing'
      'staging'        | 'staging'
      'dev'            | 'development'
      'review/app'     | 'development'
      'something-else' | 'unmapped'
    end

    with_them do
      before do
        environment.update!(name: env_name)
      end

      let(:exposed_type) { subject.send(:environment_entity).send(:type) }

      it 'has the correct environment type' do
        expect(exposed_type).to eq(env_type)
      end
    end
  end

  context 'when the deployment can be linked to a Jira issue' do
    let(:pipeline) { create(:ci_pipeline, merge_request: merge_request) }

    before do
      subject.deployable.update!(pipeline: pipeline)
    end

    %i[jira_branch jira_title].each do |trait|
      context "because it belongs to an MR with a #{trait}" do
        let(:merge_request) { create(:merge_request, trait) }

        describe '#issue_keys' do
          it 'is not empty' do
            expect(subject.issue_keys).not_to be_empty
          end
        end

        describe '#to_json' do
          it 'is valid according to the deployment info schema' do
            expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.deployment_info)
          end
        end
      end
    end
  end
end

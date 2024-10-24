# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::DeploymentEntity, feature_category: :integrations do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:project) { create_default(:project, :repository) }
  let_it_be(:environment) { create(:environment, name: 'prod', project: project) }
  let_it_be_with_refind(:deployment) { create(:deployment, environment: environment) }

  subject { described_class.represent(deployment) }

  describe '#to_json' do
    context 'when the deployment does not belong to any Jira issue' do
      before do
        allow(subject).to receive(:issue_keys).and_return([])
        allow(subject).to receive(:service_ids_from_integration_configuration).and_return([])
        allow(subject).to receive(:generate_deployment_commands).and_return(nil)
      end

      it 'can encode the object' do
        expect(subject.to_json).to be_valid_json
      end

      it 'is invalid, since it has no issue keys' do
        expect(subject.to_json).not_to match_schema(Atlassian::Schemata.deployment_info)
      end
    end

    context 'when the deployment belongs to Jira issue' do
      before do
        allow(subject).to receive(:issue_keys).and_return(['JIRA-1'])
        allow(subject).to receive(:service_ids_from_integration_configuration).and_return([])
      end

      it 'is valid according to the deployment info schema' do
        expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.deployment_info)
      end
    end

    context 'when the project has GitLab for Jira Cloud app, and service keys configured' do
      let_it_be(:integration) { create(:jira_cloud_app_integration, project: project) }

      let(:associations) { Gitlab::Json.parse(subject.to_json)['associations'] }

      it 'is valid according to the deployment info schema' do
        expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.deployment_info)
      end

      it 'includes service IDs in the association' do
        expect(associations).to include(
          { 'associationType' => 'serviceIdOrKeys', 'values' => [integration.jira_cloud_app_service_ids] }
        )
      end

      context 'when the integration has comma-separated service keys' do
        before do
          integration.update!(jira_cloud_app_service_ids: 'b:AXJpOmNsmdOJ2aWNlLzP=,b:BXJpOmNOzZXJ2aWNlLzP=')
        end

        it 'splits the keys' do
          expect(associations).to include(
            { 'associationType' => 'serviceIdOrKeys', 'values' => %w[b:AXJpOmNsmdOJ2aWNlLzP= b:BXJpOmNOzZXJ2aWNlLzP=] }
          )
        end
      end

      context 'when the integration has service keys with no comma' do
        before do
          integration.update!(jira_cloud_app_service_ids: 'b:AXJpOmNsmdOJ2aWNlLzP=')
        end

        it 'splits the keys' do
          expect(associations).to include(
            { 'associationType' => 'serviceIdOrKeys', 'values' => %w[b:AXJpOmNsmdOJ2aWNlLzP=] }
          )
        end
      end

      context 'when the integration has service keys with a comma at the end' do
        before do
          integration.update!(jira_cloud_app_service_ids: 'b:AXJpOmNsmdOJ2aWNlLzP=,')
        end

        it 'splits the keys' do
          expect(associations).to include(
            { 'associationType' => 'serviceIdOrKeys', 'values' => %w[b:AXJpOmNsmdOJ2aWNlLzP=] }
          )
        end
      end

      context 'when the integration has no service keys' do
        before do
          integration.update!(jira_cloud_app_service_ids: [])
        end

        it 'does not include the serviceIdOrKeys association type' do
          expect(associations.any? { |association| association['associationType'] == 'serviceIdOrKeys' }).to be_falsey
        end
      end

      context 'when the integration is inactive no associationType equals to serviceIdOrKeys' do
        before do
          integration.update!(active: false)
        end

        it 'does not include the serviceIdOrKeys association type' do
          expect(associations.any? { |association| association['associationType'] == 'serviceIdOrKeys' }).to be_falsey
        end
      end
    end

    context 'when the project has Jira Cloud app, deployment gating configured and state is pending' do
      before do
        deployment.update!(status: 'blocked')
      end

      let_it_be_with_reload(:integration) do
        create(:jira_cloud_app_integration, jira_cloud_app_enable_deployment_gating: true,
          jira_cloud_app_deployment_gating_environments: "production", project: project)
      end

      let(:commands) { Gitlab::Json.parse(subject.to_json)['commands'] }

      it 'is valid according to the deployment info schema' do
        expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.deployment_info)
      end

      it 'includes initiate_deployment_gating in the commands' do
        expect(commands).to include(
          { 'command' => 'initiate_deployment_gating' }
        )
      end

      context 'when the integration has comma-separated environments' do
        before do
          integration.update!(jira_cloud_app_deployment_gating_environments: 'production,development')
        end

        it 'includes initiate_deployment_gating in the commands' do
          expect(commands).to include(
            { 'command' => 'initiate_deployment_gating' }
          )
        end
      end

      context 'when the integration jira_cloud_app_enable_deployment_gating is false' do
        before do
          integration.update!(jira_cloud_app_enable_deployment_gating: false)
        end

        it 'does not includes initiate_deployment_gating in the commands' do
          expect(commands).to be(nil)
        end
      end

      context 'when the integration jira_cloud_app_deployment_gating_environments is not matching with tier' do
        before do
          integration.update!(jira_cloud_app_deployment_gating_environments: "development")
        end

        it 'does not include initiate_deployment_gating in the commands' do
          expect(commands).to be(nil)
        end
      end

      context 'when the integration jira_cloud_app_deployment_gating_environments state is not pending' do
        before do
          deployment.update!(status: 'running')
        end

        it 'does not include initiate_deployment_gating in the commands' do
          expect(commands).to be(nil)
        end
      end

      context 'when the deployment status is created' do
        before do
          deployment.update!(status: 'created')
        end

        it 'does include initiate_deployment_gating in the commands' do
          expect(commands).to include(
            { 'command' => 'initiate_deployment_gating' }
          )
        end
      end
    end

    context 'when the deployment belongs to Jira issue and Service IDs' do
      before do
        allow(subject).to receive(:issue_keys).and_return(['JIRA-1'])
        allow(subject).to receive(:service_ids_from_integration_configuration).and_return([
          { associationType: 'serviceIdOrKeys', values: [
            'b:YXJpOmNsb3VkOmdyYXBoOjpzZXJ2aWNlLzIwM2asdkMWE0LTE0MmEtNDE0Yy1hYjY4LTA1
          OGMzMDBkODAxMS8yMDdlZDkwZS1lNWMxLTExZWUtODFiNS0xMjhiNDsfa4MTk0MjQ=',
            'b:YXJpOmNsb3VkOmdyYXBoOjpzZXJ2aWNlLzIwM2asdkMWE0LTEgasdtNDE0Yy1hYjY4LTA1
          OGMzMDBkODAxMS8yMDdlZDkwZS1lNWMxLTExZWUtODFiNS0xMjhiNDsfa4MTk0MjQ='
          ] }
        ])
      end

      it 'is valid according to the deployment info schema' do
        expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.deployment_info)
      end
    end
  end

  context 'when deployment is an external deployment' do
    before do
      deployment.update!(deployable: nil)
      allow(subject).to receive(:service_ids_from_integration_configuration).and_return([])
    end

    it 'does not raise errors when serializing' do
      expect { subject.to_json }.not_to raise_error
    end
  end

  describe 'environment type' do
    using RSpec::Parameterized::TableSyntax

    where(:tier, :env_type) do
      'other' | 'unmapped'
    end

    with_them do
      before do
        subject.environment.update!(tier: tier)
      end

      let(:exposed_type) { subject.send(:environment_entity).send(:type) }

      it 'has the same type as the environment tier' do
        expect(exposed_type).to eq(env_type)
      end
    end
  end

  describe '#issue_keys' do
    # For these tests, use a Jira issue key regex that matches a set of commit messages
    # in the test repo.
    #
    # Relevant commits in this test from https://gitlab.com/gitlab-org/gitlab-test/-/commits/master:
    #
    # 1) 5f923865dde3436854e9ceb9cdb7815618d4e849 GitLab currently doesn't support patches [...]: add a commit here
    # 2) 4cd80ccab63c82b4bad16faa5193fbd2aa06df40 add directory structure for tree_helper spec
    # 3) ae73cb07c9eeaf35924a10f713b364d32b2dd34f Binary file added
    # 4) 33f3729a45c02fc67d00adb1b8bca394b0e761d9 Image added
    before do
      allow(Gitlab::Regex).to receive(:jira_issue_key_regex).and_return(/add.[a-d]/)
    end

    let(:expected_issue_keys) { ['add a', 'add d', 'added'] }

    it 'extracts issue keys from the commits' do
      expect(subject.issue_keys).to contain_exactly(*expected_issue_keys)
    end

    it 'limits the number of commits scanned' do
      stub_const("#{described_class}::COMMITS_LIMIT", 10)

      expect(subject.issue_keys).to contain_exactly('add a')
    end

    context 'when deploy happened at an older commit' do
      before do
        # SHA is from a commit between 1) and 2) in the commit list above.
        deployment.update!(sha: 'c7fbe50c7c7419d9701eebe64b1fdacc3df5b9dd')
      end

      it 'extracts only issue keys from that commit or older' do
        expect(subject.issue_keys).to contain_exactly('add d', 'added')
      end
    end

    context 'when the deployment has an associated merge request' do
      let_it_be(:pipeline) do
        create(:ci_pipeline,
          merge_request: create(:merge_request,
            title: 'Title addxa',
            description: "Description\naddxa\naddya",
            source_branch: 'feature/addza'
          )
        )
      end

      before do
        subject.deployable.update!(pipeline: pipeline)
      end

      it 'includes issue keys extracted from the merge request' do
        expect(subject.issue_keys).to contain_exactly(
          *(expected_issue_keys + %w[addxa addya addza])
        )
      end
    end

    context 'when there was a successful deploy to the environment' do
      let_it_be_with_reload(:last_deploy) do
        # SHA is from a commit between 2) and 3) in the commit list above.
        sha = '5937ac0a7beb003549fc5fd26fc247adbce4a52e'
        create(:deployment, :success, sha: sha, environment: environment, finished_at: 1.hour.ago)
      end

      shared_examples 'extracts only issue keys from commits made since that deployment' do
        specify do
          expect(subject.issue_keys).to contain_exactly('add a', 'add d')
        end
      end

      shared_examples 'ignores that deployment' do
        specify do
          expect(subject.issue_keys).to contain_exactly(*expected_issue_keys)
        end
      end

      it_behaves_like 'extracts only issue keys from commits made since that deployment'

      context 'when the deploy was for a different environment' do
        before do
          last_deploy.update!(environment: create(:environment))
        end

        it_behaves_like 'ignores that deployment'
      end

      context 'when the deploy was for a different branch or tag' do
        before do
          last_deploy.update!(ref: 'foo')
        end

        it_behaves_like 'ignores that deployment'
      end

      context 'when the deploy was not successful' do
        before do
          last_deploy.drop!
        end

        it_behaves_like 'ignores that deployment'
      end

      context 'when the deploy commit cannot be found' do
        before do
          last_deploy.update!(sha: 'foo')
        end

        it_behaves_like 'ignores that deployment'
      end

      context 'when there is a more recent deployment' do
        let_it_be(:more_recent_last_deploy) do
          # SHA is from a commit between 1) and 2) in the commit list above.
          sha = 'c7fbe50c7c7419d9701eebe64b1fdacc3df5b9dd'
          create(:deployment, :success, sha: sha, environment: environment, finished_at: 1.minute.ago)
        end

        it 'extracts only issue keys from commits made since that deployment' do
          expect(subject.issue_keys).to contain_exactly('add a')
        end
      end
    end
  end
end

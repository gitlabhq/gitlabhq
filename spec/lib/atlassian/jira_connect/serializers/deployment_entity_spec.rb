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
      end

      it 'is valid according to the deployment info schema' do
        expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.deployment_info)
      end
    end
  end

  context 'when deployment is an external deployment' do
    before do
      deployment.update!(deployable: nil)
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

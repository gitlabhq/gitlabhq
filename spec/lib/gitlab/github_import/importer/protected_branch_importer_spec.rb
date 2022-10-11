# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ProtectedBranchImporter do
  subject(:importer) { described_class.new(github_protected_branch, project, client) }

  let(:branch_name) { 'protection' }
  let(:allow_force_pushes_on_github) { true }
  let(:required_conversation_resolution) { false }
  let(:required_signatures) { false }
  let(:github_protected_branch) do
    Gitlab::GithubImport::Representation::ProtectedBranch.new(
      id: branch_name,
      allow_force_pushes: allow_force_pushes_on_github,
      required_conversation_resolution: required_conversation_resolution,
      required_signatures: required_signatures
    )
  end

  let(:project) { create(:project, :repository) }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  describe '#execute' do
    let(:create_service) { instance_double('ProtectedBranches::CreateService') }

    shared_examples 'create branch protection by the strictest ruleset' do
      let(:expected_ruleset) do
        {
          name: 'protection',
          push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
          merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
          allow_force_push: expected_allow_force_push
        }
      end

      it 'calls service with the correct arguments' do
        expect(ProtectedBranches::CreateService).to receive(:new).with(
          project,
          project.creator,
          expected_ruleset
        ).and_return(create_service)

        expect(create_service).to receive(:execute).with(skip_authorization: true)
        importer.execute
      end

      it 'creates protected branch and access levels for given github rule' do
        expect { importer.execute }.to change(ProtectedBranch, :count).by(1)
          .and change(ProtectedBranch::PushAccessLevel, :count).by(1)
          .and change(ProtectedBranch::MergeAccessLevel, :count).by(1)
      end
    end

    shared_examples 'does not change project attributes' do
      it 'does not change only_allow_merge_if_all_discussions_are_resolved' do
        expect { importer.execute }.not_to change(project, :only_allow_merge_if_all_discussions_are_resolved)
      end

      it 'does not change push_rule for the project' do
        expect(project).not_to receive(:push_rule)

        importer.execute
      end
    end

    context 'when branch is protected on GitLab' do
      before do
        create(
          :protected_branch,
          project: project,
          name: 'protect*',
          allow_force_push: allow_force_pushes_on_gitlab
        )
      end

      context 'when branch protection rule on Gitlab is stricter than on Github' do
        let(:allow_force_pushes_on_github) { true }
        let(:allow_force_pushes_on_gitlab) { false }
        let(:expected_allow_force_push) { false }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end

      context 'when branch protection rule on Github is stricter than on Gitlab' do
        let(:allow_force_pushes_on_github) { false }
        let(:allow_force_pushes_on_gitlab) { true }
        let(:expected_allow_force_push) { false }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end

      context 'when branch protection rules on Github and Gitlab are the same' do
        let(:allow_force_pushes_on_github) { true }
        let(:allow_force_pushes_on_gitlab) { true }
        let(:expected_allow_force_push) { true }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end
    end

    context 'when branch is not protected on GitLab' do
      let(:expected_allow_force_push) { true }

      it_behaves_like 'create branch protection by the strictest ruleset'
    end

    context "when branch is default" do
      before do
        allow(project).to receive(:default_branch).and_return(branch_name)
      end

      context 'when required_conversation_resolution rule is enabled' do
        let(:required_conversation_resolution) { true }

        it 'changes project settings' do
          expect { importer.execute }.to change(project, :only_allow_merge_if_all_discussions_are_resolved).to(true)
        end
      end

      context 'when required_conversation_resolution rule is disabled' do
        let(:required_conversation_resolution) { false }

        it_behaves_like 'does not change project attributes'
      end

      context 'when required_signatures rule is enabled' do
        let(:required_signatures) { true }
        let(:push_rules_feature_available?) { true }

        before do
          stub_licensed_features(push_rules: push_rules_feature_available?)
        end

        context 'when the push_rules feature is available', if: Gitlab.ee? do
          context 'when project push_rules did previously exist' do
            before do
              create(:push_rule, project: project)
            end

            it 'updates push_rule reject_unsigned_commits attribute' do
              expect { importer.execute }.to change { project.reload.push_rule.reject_unsigned_commits }.to(true)
            end
          end

          context 'when project push_rules did not previously exist' do
            it 'creates project push_rule with the enabled reject_unsigned_commits attribute' do
              expect { importer.execute }.to change(project, :push_rule).from(nil)
              expect(project.push_rule.reject_unsigned_commits).to be_truthy
            end
          end
        end

        context 'when the push_rules feature is not available' do
          let(:push_rules_feature_available?) { false }

          it_behaves_like 'does not change project attributes'
        end
      end

      context 'when required_signatures rule is disabled' do
        let(:required_signatures) { false }

        it_behaves_like 'does not change project attributes'
      end
    end

    context "when branch is not default" do
      context 'when required_conversation_resolution rule is enabled' do
        let(:required_conversation_resolution) { true }

        it_behaves_like 'does not change project attributes'
      end

      context 'when required_conversation_resolution rule is disabled' do
        let(:required_conversation_resolution) { false }

        it_behaves_like 'does not change project attributes'
      end

      context 'when required_signatures rule is enabled' do
        let(:required_signatures) { true }

        it_behaves_like 'does not change project attributes'
      end

      context 'when required_signatures rule is disabled' do
        let(:required_signatures) { false }

        it_behaves_like 'does not change project attributes'
      end
    end
  end
end

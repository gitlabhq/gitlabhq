# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ProtectedBranchImporter, feature_category: :importers do
  include Import::UserMappingHelper

  subject(:importer) { described_class.new(github_protected_branch, project, client) }

  let(:branch_name) { 'protection' }
  let(:allow_force_pushes_on_github) { false }
  let(:require_code_owner_reviews_on_github) { false }
  let(:required_conversation_resolution) { false }
  let(:required_signatures) { false }
  let(:required_pull_request_reviews) { false }
  let(:expected_push_access_level) { Gitlab::Access::MAINTAINER }
  let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }
  let(:expected_allow_force_push) { false }
  let(:expected_code_owner_approval_required) { false }
  let(:allowed_to_push_users) { [] }
  let(:push_access_levels_number) { 1 }
  let(:push_access_levels_attributes) { [{ access_level: expected_push_access_level }] }
  let(:github_protected_branch) do
    Gitlab::GithubImport::Representation::ProtectedBranch.new(
      id: branch_name,
      allow_force_pushes: allow_force_pushes_on_github,
      required_conversation_resolution: required_conversation_resolution,
      required_signatures: required_signatures,
      required_pull_request_reviews: required_pull_request_reviews,
      require_code_owner_reviews: require_code_owner_reviews_on_github,
      allowed_to_push_users: allowed_to_push_users
    )
  end

  let(:project) do
    create(:project, :repository, :with_import_url, :import_user_mapping_enabled, import_type: Import::SOURCE_GITHUB)
  end

  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  before do
    allow(client).to receive(:user).and_return({ name: 'Github user name' })
  end

  describe '#execute' do
    let(:create_service) { instance_double('ProtectedBranches::CreateService') }

    shared_examples 'create branch protection by the strictest ruleset' do
      let(:expected_ruleset) do
        {
          name: 'protection',
          push_access_levels_attributes: push_access_levels_attributes,
          merge_access_levels_attributes: [{ access_level: expected_merge_access_level }],
          allow_force_push: expected_allow_force_push,
          code_owner_approval_required: expected_code_owner_approval_required,
          importing: true
        }
      end

      it 'calls service with the correct arguments' do
        valid_protected_branch = instance_double('ProtectedBranch',
          validate!: true,
          push_access_levels: []
        )

        expect(ProtectedBranches::CreateService).to receive(:new).with(
          project,
          project.creator,
          expected_ruleset
        ).and_return(create_service)

        expect(create_service).to receive(:execute).with(skip_authorization: true).and_return(valid_protected_branch)
        importer.execute
      end

      it 'creates protected branch and access levels for given github rule' do
        expect { importer.execute }.to change(ProtectedBranch, :count).by(1)
          .and change(ProtectedBranch::PushAccessLevel, :count).by(push_access_levels_number)
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
      using RSpec::Parameterized::TableSyntax

      where(
        :allow_force_pushes_on_github,
        :allow_force_pushes_on_gitlab,
        :expected_allow_force_push
      ) do
        true   | true   | true
        true   | false  | false
        false  | true   | false
        false  | false  | false
      end

      with_them do
        before do
          create(
            :protected_branch,
            project: project,
            name: 'protect*',
            allow_force_push: allow_force_pushes_on_gitlab
          )
        end

        it_behaves_like 'create branch protection by the strictest ruleset'
      end
    end

    context 'when branch is not protected on GitLab' do
      let(:allow_force_pushes_on_github) { true }
      let(:expected_allow_force_push) { true }

      it_behaves_like 'create branch protection by the strictest ruleset'
    end

    context "when branch is default" do
      before do
        allow(project).to receive(:default_branch).and_return(branch_name)
      end

      context 'when "allow force pushes - everyone" rule is enabled' do
        let(:allow_force_pushes_on_github) { true }

        context 'when default branch protection is applied' do
          before do
            stub_application_setting(default_branch_protection_defaults:
                                       Gitlab::Access::BranchProtection.protected_fully)
          end

          let(:expected_allow_force_push) { false }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end

        context 'when there is no default branch protection' do
          before do
            stub_application_setting(default_branch_protection_defaults:
                                       Gitlab::Access::BranchProtection.protection_none)
          end

          let(:expected_allow_force_push) { allow_force_pushes_on_github }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end
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

    context 'when branch is not default' do
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

    context 'when required_pull_request_reviews rule is enabled on GitHub' do
      let(:required_pull_request_reviews) { true }

      context 'when no user is allowed to bypass push restrictions' do
        let(:expected_push_access_level) { Gitlab::Access::NO_ACCESS }
        let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end

      context 'when there are users who are allowed to bypass push restrictions' do
        let(:user_references) { placeholder_user_references(::Import::SOURCE_GITHUB, project.import_state.id) }

        context 'when the protected_refs_for_users feature is available', if: Gitlab.ee? do
          let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }

          let(:allowed_to_push_users) do
            [Gitlab::GithubImport::Representation::User.new(id: 1, login: 'github_username')]
          end

          let(:push_access_levels_number) { 1 }
          let(:push_access_levels_attributes) do
            [
              { user_id: kind_of(Integer), importing: true }
            ]
          end

          before do
            stub_licensed_features(protected_refs_for_users: true)
          end

          it_behaves_like 'create branch protection by the strictest ruleset'

          it 'pushes placeholder references' do
            importer.execute

            imported_push_access_level = project.protected_branches.first.push_access_levels.first
            source_user = Import::SourceUser.last

            expect(source_user).to have_attributes(
              source_user_identifier: '1',
              source_username: 'github_username'
            )
            expect(user_references).to match_array([
              ['ProtectedBranch::PushAccessLevel', imported_push_access_level.id, 'user_id', source_user.id]
            ])
          end

          context 'when user mapping is disabled' do
            let(:owner_id) { project.owner.id }
            let(:owner_username) { project.owner.username }
            let(:other_user) { create(:user) }
            let(:other_user_id) { other_user.id }
            let(:other_user_username) { other_user.username }
            let(:allowed_to_push_users) do
              [
                Gitlab::GithubImport::Representation::User.new(id: owner_id, login: owner_username),
                Gitlab::GithubImport::Representation::User.new(id: other_user_id, login: other_user_username)
              ]
            end

            before do
              project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
            end

            context 'when the users are found on GitLab' do
              let(:push_access_levels_number) { 2 }
              let(:push_access_levels_attributes) do
                [
                  { user_id: owner_id, importing: true },
                  { user_id: other_user_id, importing: true }
                ]
              end

              before do
                project.add_member(other_user, :maintainer)
                allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
                  allow(finder).to receive(:find).with(owner_id, owner_username).and_return(owner_id)
                  allow(finder).to receive(:find).with(other_user_id, other_user_username).and_return(other_user_id)
                end
              end

              it_behaves_like 'create branch protection by the strictest ruleset'

              it 'does not push placeholder references' do
                importer.execute

                expect(user_references).to be_empty
              end
            end

            context 'when one of found users is not a member of the imported project' do
              let(:push_access_levels_number) { 1 }
              let(:push_access_levels_attributes) do
                [
                  { user_id: owner_id, importing: true }
                ]
              end

              before do
                allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
                  allow(finder).to receive(:find).with(owner_id, owner_username).and_return(owner_id)
                  allow(finder).to receive(:find).with(other_user_id, other_user_username).and_return(other_user_id)
                end
              end

              it_behaves_like 'create branch protection by the strictest ruleset'

              it 'does not push placeholder references' do
                importer.execute

                expect(user_references).to be_empty
              end
            end

            context 'when the users are not found on GitLab' do
              before do
                allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
                  allow(finder).to receive(:find).and_return(nil)
                end
              end

              let(:expected_push_access_level) { Gitlab::Access::NO_ACCESS }
              let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }
              let(:push_access_levels_attributes) { [{ access_level: expected_push_access_level }] }

              it_behaves_like 'create branch protection by the strictest ruleset'
            end
          end
        end

        context 'when the protected_refs_for_users feature is not available' do
          before do
            stub_licensed_features(protected_refs_for_users: false)
          end

          let(:expected_push_access_level) { Gitlab::Access::NO_ACCESS }
          let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }
          let(:push_access_levels_attributes) { [{ access_level: expected_push_access_level }] }

          it_behaves_like 'create branch protection by the strictest ruleset'

          it 'does not push any placeholder references' do
            expect { importer.execute }.not_to change(Import::SourceUser, :count)
            expect(user_references).to be_empty
          end
        end
      end
    end

    context 'when required_pull_request_reviews rule is disabled on GitHub' do
      let(:required_pull_request_reviews) { false }

      context 'when branch is default' do
        before do
          allow(project).to receive(:default_branch).and_return(branch_name)
        end

        context 'when default branch protection is partially protected' do
          before do
            stub_application_setting(default_branch_protection_defaults:
                                       Gitlab::Access::BranchProtection.protection_partial)
          end

          let(:expected_push_access_level) { Gitlab::Access::DEVELOPER }
          let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end

        context 'when default branch protection is protected against developer pushes' do
          before do
            stub_application_setting(default_branch_protection_defaults:
                                       Gitlab::Access::BranchProtection.protected_against_developer_pushes)
          end

          let(:expected_push_access_level) { Gitlab::Access::MAINTAINER }
          let(:expected_merge_access_level) { Gitlab::Access::DEVELOPER }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end
      end

      context 'when branch is protected on GitLab' do
        let(:protected_branch) do
          create(
            :protected_branch,
            project: project,
            name: 'protect*',
            allow_force_push: true,
            code_owner_approval_required: false
          )
        end

        let(:push_access_level) { protected_branch.push_access_levels.first }
        let(:merge_access_level) { protected_branch.merge_access_levels.first }

        context 'when there is branch protection rule for the role' do
          context 'when No one can merge' do
            before do
              merge_access_level.update_column(:access_level, Gitlab::Access::NO_ACCESS)
            end

            let(:expected_push_access_level) { push_access_level.access_level }
            let(:expected_merge_access_level) { Gitlab::Access::NO_ACCESS }

            it_behaves_like 'create branch protection by the strictest ruleset'
          end

          context 'when Maintainers and Developers can merge' do
            before do
              merge_access_level.update_column(:access_level, Gitlab::Access::DEVELOPER)
            end

            let(:gitlab_push_access_level) { push_access_level.access_level }
            let(:gitlab_merge_access_level) { merge_access_level.access_level }
            let(:expected_push_access_level) { gitlab_push_access_level }
            let(:expected_merge_access_level) { [gitlab_merge_access_level, github_default_merge_access_level].max }
            let(:github_default_merge_access_level) do
              Gitlab::GithubImport::Importer::ProtectedBranchImporter::GITHUB_DEFAULT_MERGE_ACCESS_LEVEL
            end

            it_behaves_like 'create branch protection by the strictest ruleset'
          end
        end

        context 'when there is no branch protection rule for the role' do
          before do
            push_access_level.update_column(:user_id, project.owner.id)
            merge_access_level.update_column(:user_id, project.owner.id)
          end

          let(:expected_push_access_level) { ProtectedBranch::PushAccessLevel::GITLAB_DEFAULT_ACCESS_LEVEL }
          let(:expected_merge_access_level) { Gitlab::Access::MAINTAINER }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end
      end

      context 'when branch is neither default nor protected on GitLab' do
        let(:expected_push_access_level) { ProtectedBranch::PushAccessLevel::GITLAB_DEFAULT_ACCESS_LEVEL }
        let(:expected_merge_access_level) { ProtectedBranch::MergeAccessLevel::GITLAB_DEFAULT_ACCESS_LEVEL }

        it_behaves_like 'create branch protection by the strictest ruleset'
      end
    end

    context 'when the code_owner_approval_required feature is available', if: Gitlab.ee? do
      before do
        stub_licensed_features(code_owner_approval_required: true)
      end

      context 'when branch is protected on GitLab' do
        using RSpec::Parameterized::TableSyntax

        where(
          :require_code_owner_reviews_on_github,
          :require_code_owner_reviews_on_gitlab,
          :expected_code_owner_approval_required
        ) do
          true   | true   | true
          true   | false  | true
          false  | true   | true
          false  | false  | false
        end

        with_them do
          before do
            create(
              :protected_branch,
              project: project,
              name: 'protect*',
              allow_force_push: true,
              code_owner_approval_required: require_code_owner_reviews_on_gitlab
            )
          end

          it_behaves_like 'create branch protection by the strictest ruleset'
        end
      end

      context 'when branch is not protected on GitLab' do
        context 'when require_code_owner_reviews rule is enabled on GitHub' do
          let(:require_code_owner_reviews_on_github) { true }
          let(:expected_code_owner_approval_required) { true }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end

        context 'when require_code_owner_reviews rule is disabled on GitHub' do
          let(:require_code_owner_reviews_on_github) { false }
          let(:expected_code_owner_approval_required) { false }

          it_behaves_like 'create branch protection by the strictest ruleset'
        end
      end
    end

    context 'when the code_owner_approval_required feature is not available' do
      before do
        stub_licensed_features(code_owner_approval_required: false)
      end

      let(:require_code_owner_reviews_on_github) { true }
      let(:expected_code_owner_approval_required) { false }

      it_behaves_like 'create branch protection by the strictest ruleset'
    end

    context 'when branch is invalid' do
      before do
        allow_next_instance_of(ProtectedBranches::CreateService) do |service|
          allow(service).to receive(:execute).and_return(ProtectedBranch.new)
        end
      end

      it 'raises a ActiveRecord::RecordInvalid error' do
        expect { importer.execute }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

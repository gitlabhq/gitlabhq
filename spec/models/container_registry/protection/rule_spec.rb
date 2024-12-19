# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::Rule, type: :model, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:container_registry_protection_rules) }
  end

  describe 'enums' do
    it {
      is_expected.to(
        define_enum_for(:minimum_access_level_for_push)
          .with_values(
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER,
            admin: Gitlab::Access::ADMIN
          )
          .with_prefix(:minimum_access_level_for_push)
      )
    }

    it {
      is_expected.to(
        define_enum_for(:minimum_access_level_for_delete)
        .with_values(
          maintainer: Gitlab::Access::MAINTAINER,
          owner: Gitlab::Access::OWNER,
          admin: Gitlab::Access::ADMIN
        )
        .with_prefix(:minimum_access_level_for_delete)
      )
    }
  end

  describe 'validations' do
    subject { build(:container_registry_protection_rule) }

    describe '#repository_path_pattern' do
      it { is_expected.to validate_presence_of(:repository_path_pattern) }
      it { is_expected.to validate_length_of(:repository_path_pattern).is_at_most(255) }

      describe '#path_pattern_starts_with_project_full_path' do
        using RSpec::Parameterized::TableSyntax

        let(:project_downcased_path) { build(:project) }
        let(:project_mixcased_path) { build(:project, path: 'namespace1/MIXCASED-project-path') }

        subject(:container_registry_protection_rule) { build(:container_registry_protection_rule, project: project) }

        # rubocop:disable Layout/LineLength -- Avoid formatting to keep oneline table syntax
        where(:project, :repository_path_pattern, :allowed) do
          ref(:project_downcased_path) | lazy { project_downcased_path.full_path }                                | true
          ref(:project_downcased_path) | lazy { "#{project_downcased_path.full_path}*" }                          | true
          ref(:project_downcased_path) | lazy { "#{project_downcased_path.full_path}/*" }                         | true
          ref(:project_downcased_path) | lazy { "#{project_downcased_path.full_path}/sub-image*" }                | true
          ref(:project_downcased_path) | lazy { "#{project_downcased_path.full_path}/sub-image/*" }               | true
          ref(:project_downcased_path) | lazy { "#{project_downcased_path.full_path}/sub-image/*/sub-sub-image" } | true
          ref(:project_downcased_path) | lazy { "#{project_downcased_path.full_path}/sub-image/sub-sub-image*" }  | true

          ref(:project_downcased_path) | lazy { project_downcased_path.full_path.upcase }                         | false
          ref(:project_downcased_path) | lazy { "*#{project_downcased_path.path}" }                               | false
          ref(:project_downcased_path) | lazy { "*#{project_downcased_path.path}/*" }                             | false
          ref(:project_downcased_path) | lazy { "any-project-scope/#{project_downcased_path.path}" }              | false
          ref(:project_downcased_path) | lazy { build(:project).full_path }                                       | false
          ref(:project_downcased_path) | lazy { project_downcased_path.path }                                     | false
          ref(:project_downcased_path) | nil                                                                      | false

          ref(:project_mixcased_path)  | lazy { project_mixcased_path.full_path.downcase }                        | true
          ref(:project_mixcased_path)  | lazy { "#{project_mixcased_path.full_path.downcase}*" }                  | true
          ref(:project_mixcased_path)  | lazy { "#{project_mixcased_path.full_path.downcase}/sub-image/*" }       | true

          ref(:project_mixcased_path)  | lazy { project_mixcased_path.full_path }                                 | false
          ref(:project_mixcased_path)  | lazy { project_mixcased_path.full_path.upcase }                          | false
          ref(:project_mixcased_path)  | lazy { "#{project_mixcased_path.full_path}/sub-image*" }                 | false
        end
        # rubocop:enable Layout/LineLength

        with_them do
          if params[:allowed]
            it { is_expected.to allow_values(repository_path_pattern).for(:repository_path_pattern) }
          else
            it { is_expected.not_to allow_values(repository_path_pattern).for(:repository_path_pattern) }
          end
        end
      end
    end

    describe '#at_least_one_minimum_access_level_must_be_present' do
      where(:minimum_access_level_for_delete, :minimum_access_level_for_push, :valid) do
        :maintainer | :maintainer | true
        :maintainer | nil         | true
        nil         | :maintainer | true
        nil         | nil         | false
      end

      with_them do
        subject(:container_registry_protection_rule) {
          build(:container_registry_protection_rule, minimum_access_level_for_delete: minimum_access_level_for_delete,
            minimum_access_level_for_push: minimum_access_level_for_push)
        }

        if params[:valid]
          it { is_expected.to be_valid }
        else
          it 'is invalid' do
            expect(container_registry_protection_rule).not_to be_valid
            expect(container_registry_protection_rule.errors[:base]).to include(
              'A rule must have at least a minimum access role for push or delete.'
            )
          end
        end
      end
    end
  end

  describe '.for_repository_path' do
    let_it_be(:project) { create(:project) }

    let_it_be(:container_registry_protection_rule) do
      create(:container_registry_protection_rule,
        project: project,
        repository_path_pattern: "#{project.full_path}/my_container"
      )
    end

    let_it_be(:protection_rule_with_wildcard_start) do
      create(:container_registry_protection_rule,
        project: project,
        repository_path_pattern: "#{project.full_path}/*my_container-with-wildcard-start"
      )
    end

    let_it_be(:protection_rule_with_wildcard_end) do
      create(:container_registry_protection_rule,
        project: project,
        repository_path_pattern: "#{project.full_path}/my_container-with-wildcard-end*"
      )
    end

    let_it_be(:protection_rule_with_wildcard_middle) do
      create(:container_registry_protection_rule,
        project: project,
        repository_path_pattern: "#{project.full_path}/*my_container-with-wildcard-middle"
      )
    end

    let_it_be(:protection_rule_with_wildcard_start_middle_end) do
      create(:container_registry_protection_rule,
        project: project,
        repository_path_pattern: "#{project.full_path}/**my_container**with-wildcard-start-middle-end**"
      )
    end

    let_it_be(:protection_rule_with_underscore) do
      create(:container_registry_protection_rule,
        project: project,
        repository_path_pattern: "#{project.full_path}/my_container-with_underscore"
      )
    end

    let_it_be(:protection_rule_with_regex_char_period) do
      create(:container_registry_protection_rule,
        project: project,
        repository_path_pattern: "#{project.full_path}/my_container-with-regex-char-period.*"
      )
    end

    let(:repository_path) { container_registry_protection_rule.repository_path_pattern }

    subject { described_class.for_repository_path(repository_path) }

    # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
    context 'with several container registry protection rule scenarios' do
      where(:repository_path, :expected_container_registry_protection_rules) do
        lazy { "#{project.full_path}/my_container" }                                                              | [ref(:container_registry_protection_rule)]
        lazy { "#{project.full_path}/my2container" }                                                              | []
        lazy { "#{project.full_path}/my_container-2" }                                                            | []

        # With wildcard pattern at the start
        lazy { "#{project.full_path}/my_container-with-wildcard-start" }                                          | [ref(:protection_rule_with_wildcard_start)]
        lazy { "#{project.full_path}/my_container-with-wildcard-start-end" }                                      | []
        lazy { "#{project.full_path}/anychar-my_container-with-wildcard-start" }                                  | [ref(:protection_rule_with_wildcard_start)]
        lazy { "#{project.full_path}/anychar-my_container-with-wildcard-start-anychar" }                          | []

        # With wildcard pattern at the end
        lazy { "#{project.full_path}/my_container-with-wildcard-end" }                                            | [ref(:protection_rule_with_wildcard_end)]
        lazy { "#{project.full_path}/my_container-with-wildcard-end-anychar:1234567890" }                         | [ref(:protection_rule_with_wildcard_end)]
        lazy { "#{project.full_path}/anychar-my_container-with-wildcard-end" }                                    | []
        lazy { "#{project.full_path}/anychar-my_container-with-wildcard-end-anychar:1234567890" }                 | []

        # With wildcard pattern in the middle
        lazy { "#{project.full_path}/my_container-with-wildcard-middle" }                                         | [ref(:protection_rule_with_wildcard_middle)]
        lazy { "#{project.full_path}/anychar-my_container-with-wildcard-middle" }                                 | [ref(:protection_rule_with_wildcard_middle)]
        lazy { "#{project.full_path}/anychar-my_container-anychar-wildcard-middle-anychar" }                      | []

        # With double wildcard pattern
        lazy { "#{project.full_path}/my_container-with-wildcard-start-middle-end" }                               | [ref(:protection_rule_with_wildcard_start_middle_end)]
        lazy { "#{project.full_path}/anychar-my_container-anychar-with-wildcard-start-middle-end-anychar" }       | [ref(:protection_rule_with_wildcard_start_middle_end)]
        lazy { "#{project.full_path}/****my_container-*****-with-wildcard-start-middle-end****" }                 | [ref(:protection_rule_with_wildcard_start_middle_end)]
        lazy { "other-#{project.full_path}/anychar-my_container-anychar-with-wildcard-start-middle-end-anychar" } | []

        # With underscore
        lazy { "#{project.full_path}/my_container-with_underscore" }                                              | [ref(:protection_rule_with_underscore)]
        lazy { "#{project.full_path}/my_container-with*underscore" }                                              | []
        lazy { "#{project.full_path}/my_container-with_any_underscore" }                                          | []

        # With regex char period
        lazy { "#{project.full_path}/my_container-with-regex-char-period.*" }                                     | [ref(:protection_rule_with_regex_char_period)]
        lazy { "#{project.full_path}/my_container-with-regex-char-period.anychar" }                               | [ref(:protection_rule_with_regex_char_period)]
        lazy { "#{project.full_path}/my_container-with-regex-char-period." }                                      | [ref(:protection_rule_with_regex_char_period)]
        lazy { "#{project.full_path}/my_container-with-regex-char-period" }                                       | []
        lazy { "#{project.full_path}/my_container-with-regex-char-period-any" }                                   | []

        # Special cases
        nil                                                                                                     | []
        ''                                                                                                      | []
        'other_project_scope/any_container'                                                                     | []
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it { is_expected.to match_array(expected_container_registry_protection_rules) }
      end
    end

    context 'with multiple matching container registry protection rules' do
      let!(:container_registry_protection_rule_second_match) do
        create(:container_registry_protection_rule, project: project, repository_path_pattern: "#{repository_path}*")
      end

      it {
        is_expected.to contain_exactly(container_registry_protection_rule_second_match,
          container_registry_protection_rule)
      }
    end
  end

  describe '.for_push_exists?' do
    subject do
      project
      .container_registry_protection_rules
      .for_push_exists?(
        access_level: access_level,
        repository_path: repository_path
      )
    end

    context 'when the repository path matches multiple protection rules' do
      # The abbreviation `crpr` stands for container registry protection rule
      let_it_be(:project_with_crpr) { create(:project) }
      let_it_be(:project_without_crpr) { create(:project) }

      let_it_be(:protection_rule_for_developer) do
        create(:container_registry_protection_rule,
          project: project_with_crpr,
          repository_path_pattern: "#{project_with_crpr.full_path}/my-container-stage*",
          minimum_access_level_for_push: :maintainer
        )
      end

      let_it_be(:protection_rule_for_maintainer) do
        create(:container_registry_protection_rule,
          project: project_with_crpr,
          repository_path_pattern: "#{project_with_crpr.full_path}/my-container-prod*",
          minimum_access_level_for_push: :owner
        )
      end

      let_it_be(:protection_rule_for_owner) do
        create(:container_registry_protection_rule,
          project: project_with_crpr,
          repository_path_pattern: "#{project_with_crpr.full_path}/my-container-release*",
          minimum_access_level_for_push: :admin
        )
      end

      let_it_be(:protection_rule_overlapping_for_developer) do
        create(:container_registry_protection_rule,
          project: project_with_crpr,
          repository_path_pattern: "#{project_with_crpr.full_path}/my-container-*",
          minimum_access_level_for_push: :maintainer
        )
      end

      # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
      where(:project, :access_level, :repository_path, :for_push_exists) do
        ref(:project_with_crpr)    | Gitlab::Access::REPORTER   | lazy { "#{project_with_crpr.full_path}/my-container-stage-sha-1234" }   | true
        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | lazy { "#{project_with_crpr.full_path}/my-container-stage-sha-1234" }   | true
        ref(:project_with_crpr)    | Gitlab::Access::MAINTAINER | lazy { "#{project_with_crpr.full_path}/my-container-stage-sha-1234" }   | false
        ref(:project_with_crpr)    | Gitlab::Access::MAINTAINER | lazy { "#{project_with_crpr.full_path}/my-container-stage-sha-1234" }   | false
        ref(:project_with_crpr)    | Gitlab::Access::OWNER      | lazy { "#{project_with_crpr.full_path}/my-container-stage-sha-1234" }   | false
        ref(:project_with_crpr)    | Gitlab::Access::ADMIN      | lazy { "#{project_with_crpr.full_path}/my-container-stage-sha-1234" }   | false

        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | lazy { "#{project_with_crpr.full_path}/my-container-prod-sha-1234" }    | true
        ref(:project_with_crpr)    | Gitlab::Access::MAINTAINER | lazy { "#{project_with_crpr.full_path}/my-container-prod-sha-1234" }    | true
        ref(:project_with_crpr)    | Gitlab::Access::OWNER      | lazy { "#{project_with_crpr.full_path}/my-container-prod-sha-1234" }    | false
        ref(:project_with_crpr)    | Gitlab::Access::ADMIN      | lazy { "#{project_with_crpr.full_path}/my-container-prod-sha-1234" }    | false

        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | lazy { "#{project_with_crpr.full_path}/my-container-release-v1" }       | true
        ref(:project_with_crpr)    | Gitlab::Access::OWNER      | lazy { "#{project_with_crpr.full_path}/my-container-release-v1" }       | true
        ref(:project_with_crpr)    | Gitlab::Access::ADMIN      | lazy { "#{project_with_crpr.full_path}/my-container-release-v1" }       | false

        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | lazy { "#{project_with_crpr.full_path}/my-container-any-suffix" }       | true
        ref(:project_with_crpr)    | Gitlab::Access::MAINTAINER | lazy { "#{project_with_crpr.full_path}/my-container-any-suffix" }       | false
        ref(:project_with_crpr)    | Gitlab::Access::OWNER      | lazy { "#{project_with_crpr.full_path}/my-container-any-suffix" }       | false

        # For non-matching repository_path
        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | lazy { "#{project_with_crpr.full_path}/non-matching-container" }        | false

        # For no access level
        ref(:project_with_crpr)    | Gitlab::Access::NO_ACCESS  | lazy { "#{project_with_crpr.full_path}/my-container-prod-sha-1234" }    | true

        # Edge cases
        ref(:project_with_crpr)    | 0                          | ''                                                                      | false
        ref(:project_with_crpr)    | nil                        | nil                                                                     | false
        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | nil                                                                     | false
        ref(:project_with_crpr)    | nil                        | lazy { "#{project_with_crpr.full_path}/non-matching-container" }        | false

        # For projects that have no container registry protection rules
        ref(:project_without_crpr) | Gitlab::Access::DEVELOPER  | lazy { "#{project_without_crpr.full_path}/my-container-prod-sha-1234" } | false
        ref(:project_without_crpr) | Gitlab::Access::MAINTAINER | lazy { "#{project_without_crpr.full_path}/my-container-prod-sha-1234" } | false
        ref(:project_without_crpr) | Gitlab::Access::OWNER      | lazy { "#{project_without_crpr.full_path}/my-container-prod-sha-1234" } | false
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it { is_expected.to eq for_push_exists }
      end
    end
  end

  describe '.for_push_exists_for_projects_and_repository_paths' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project1_crpr) { create(:container_registry_protection_rule, project: project1) }

    let_it_be(:project2) { create(:project) }
    let_it_be(:project2_crpr) { create(:container_registry_protection_rule, project: project2) }

    let_it_be(:unprotected_project) { create(:project) }

    let(:single_project_input) do
      [
        [project1.id, project1_crpr.repository_path_pattern],
        [project1.id, "#{project1_crpr.repository_path_pattern}/unprotected"]
      ]
    end

    let(:single_project_expected_result) do
      [
        { "project_id" => project1.id, "repository_path" => project1_crpr.repository_path_pattern,
          "protected" => true },
        { "project_id" => project1.id, "repository_path" => "#{project1_crpr.repository_path_pattern}/unprotected",
          "protected" => false }
      ]
    end

    let(:multi_projects_input) do
      [
        *single_project_input,
        [project2.id, project2_crpr.repository_path_pattern],
        [project2.id, "#{project2_crpr.repository_path_pattern}/unprotected"]
      ]
    end

    let(:multi_projects_expected_result) do
      [
        *single_project_expected_result,
        { "project_id" => project2.id, "repository_path" => project2_crpr.repository_path_pattern,
          "protected" => true },
        { "project_id" => project2.id, "repository_path" => "#{project2_crpr.repository_path_pattern}/unprotected",
          "protected" => false }
      ]
    end

    let(:unprotected_projects_input) do
      [
        *multi_projects_input,
        [unprotected_project.id, "#{unprotected_project.full_path}/unprotected1"],
        [unprotected_project.id, "#{unprotected_project.full_path}/unprotected2"]
      ]
    end

    let(:unprotected_projects_expected_result) do
      [
        *multi_projects_expected_result,
        { "project_id" => unprotected_project.id, "repository_path" => "#{unprotected_project.full_path}/unprotected1",
          "protected" => false },
        { "project_id" => unprotected_project.id, "repository_path" => "#{unprotected_project.full_path}/unprotected2",
          "protected" => false }
      ]
    end

    subject { described_class.for_push_exists_for_projects_and_repository_paths(projects_and_repository_paths).to_a }

    where(:projects_and_repository_paths, :expected_result) do
      ref(:single_project_input)       | ref(:single_project_expected_result)
      ref(:multi_projects_input)       | ref(:multi_projects_expected_result)
      ref(:unprotected_projects_input) | ref(:unprotected_projects_expected_result)
      nil                              | []
      []                               | []
    end

    with_them do
      it { is_expected.to match_array expected_result }
    end
  end
end

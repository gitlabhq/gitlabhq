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
        define_enum_for(:push_protected_up_to_access_level)
          .with_values(
            developer: Gitlab::Access::DEVELOPER,
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER
          )
          .with_prefix(:push_protected_up_to)
      )
    }

    it {
      is_expected.to(
        define_enum_for(:delete_protected_up_to_access_level)
          .with_values(
            developer: Gitlab::Access::DEVELOPER,
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER
          )
          .with_prefix(:delete_protected_up_to)
      )
    }
  end

  describe 'validations' do
    subject { build(:container_registry_protection_rule) }

    describe '#repository_path_pattern' do
      it { is_expected.to validate_presence_of(:repository_path_pattern) }
      it { is_expected.to validate_length_of(:repository_path_pattern).is_at_most(255) }
    end

    describe '#delete_protected_up_to_access_level' do
      it { is_expected.to validate_presence_of(:delete_protected_up_to_access_level) }
    end

    describe '#push_protected_up_to_access_level' do
      it { is_expected.to validate_presence_of(:push_protected_up_to_access_level) }
    end
  end

  describe '.for_repository_path' do
    let_it_be(:container_registry_protection_rule) do
      create(:container_registry_protection_rule, repository_path_pattern: 'my-scope/my_container')
    end

    let_it_be(:protection_rule_with_wildcard_start) do
      create(:container_registry_protection_rule, repository_path_pattern: '*my-scope/my_container-with-wildcard-start')
    end

    let_it_be(:protection_rule_with_wildcard_end) do
      create(:container_registry_protection_rule, repository_path_pattern: 'my-scope/my_container-with-wildcard-end*')
    end

    let_it_be(:protection_rule_with_wildcard_middle) do
      create(:container_registry_protection_rule,
        repository_path_pattern: 'my-scope/*my_container-with-wildcard-middle')
    end

    let_it_be(:protection_rule_with_wildcard_double) do
      create(:container_registry_protection_rule,
        repository_path_pattern: '**my-scope/**my_container-with-wildcard-double**')
    end

    let_it_be(:protection_rule_with_underscore) do
      create(:container_registry_protection_rule, repository_path_pattern: 'my-scope/my_container-with_____underscore')
    end

    let_it_be(:protection_rule_with_regex_chars) do
      create(:container_registry_protection_rule, repository_path_pattern: 'my-scope/my_container-with-regex-chars.+')
    end

    let(:repository_path) { container_registry_protection_rule.repository_path_pattern }

    subject { described_class.for_repository_path(repository_path) }

    context 'with several container registry protection rule scenarios' do
      where(:repository_path, :expected_container_registry_protection_rules) do
        'my-scope/my_container'                                         | [ref(:container_registry_protection_rule)]
        'my-scope/my2container'                                         | []
        'my-scope/my_container-2'                                       | []

        # With wildcard pattern at the start
        'my-scope/my_container-with-wildcard-start'                     | [ref(:protection_rule_with_wildcard_start)]
        'my-scope/my_container-with-wildcard-start-any'                 | []
        'prefix-my-scope/my_container-with-wildcard-start'              | [ref(:protection_rule_with_wildcard_start)]
        'prefix-my-scope/my_container-with-wildcard-start-any'          | []

        # With wildcard pattern at the end
        'my-scope/my_container-with-wildcard-end'                       | [ref(:protection_rule_with_wildcard_end)]
        'my-scope/my_container-with-wildcard-end:1234567890'            | [ref(:protection_rule_with_wildcard_end)]
        'prefix-my-scope/my_container-with-wildcard-end'                | []
        'prefix-my-scope/my_container-with-wildcard-end:1234567890'     | []

        # With wildcard pattern in the middle
        'my-scope/my_container-with-wildcard-middle'                    | [ref(:protection_rule_with_wildcard_middle)]
        'my-scope/any-my_container-with-wildcard-middle'                | [ref(:protection_rule_with_wildcard_middle)]
        'my-scope/any-my_container-my_container-wildcard-middle-any'    | []

        # With double wildcard pattern
        'my-scope/my_container-with-wildcard-double'                    | [ref(:protection_rule_with_wildcard_double)]
        'prefix-my-scope/any-my_container-with-wildcard-double-any'     | [ref(:protection_rule_with_wildcard_double)]
        '****my-scope/****my_container-with-wildcard-double****'        | [ref(:protection_rule_with_wildcard_double)]
        'prefix-@other-scope/any-my_container-with-wildcard-double-any' | []

        # With underscore
        'my-scope/my_container-with_____underscore'                     | [ref(:protection_rule_with_underscore)]
        'my-scope/my_container-with_any_underscore'                     | []

        'my-scope/my_container-with-regex-chars.+'                      | [ref(:protection_rule_with_regex_chars)]
        'my-scope/my_container-with-regex-chars.'                       | []
        'my-scope/my_container-with-regex-chars'                        | []
        'my-scope/my_container-with-regex-chars-any'                    | []

        # Special cases
        nil                                                             | []
        ''                                                              | []
        'any_container'                                                 | []
      end

      with_them do
        it { is_expected.to match_array(expected_container_registry_protection_rules) }
      end
    end

    context 'with multiple matching container registry protection rules' do
      let!(:container_registry_protection_rule_second_match) do
        create(:container_registry_protection_rule, repository_path_pattern: "#{repository_path}*")
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
          repository_path_pattern: 'my-scope/my-container-stage*',
          project: project_with_crpr,
          push_protected_up_to_access_level: :developer
        )
      end

      let_it_be(:protection_rule_for_maintainer) do
        create(:container_registry_protection_rule,
          repository_path_pattern: 'my-scope/my-container-prod*',
          project: project_with_crpr,
          push_protected_up_to_access_level: :maintainer
        )
      end

      let_it_be(:protection_rule_for_owner) do
        create(:container_registry_protection_rule,
          repository_path_pattern: 'my-scope/my-container-release*',
          project: project_with_crpr,
          push_protected_up_to_access_level: :owner
        )
      end

      let_it_be(:protection_rule_overlapping_for_developer) do
        create(:container_registry_protection_rule,
          repository_path_pattern: 'my-scope/my-container-*',
          project: project_with_crpr,
          push_protected_up_to_access_level: :developer
        )
      end

      where(:project, :access_level, :repository_path, :push_protected) do
        ref(:project_with_crpr)    | Gitlab::Access::REPORTER   | 'my-scope/my-container-stage-sha-1234' | true
        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | 'my-scope/my-container-stage-sha-1234' | true
        ref(:project_with_crpr)    | Gitlab::Access::MAINTAINER | 'my-scope/my-container-stage-sha-1234' | false
        ref(:project_with_crpr)    | Gitlab::Access::MAINTAINER | 'my-scope/my-container-stage-sha-1234' | false
        ref(:project_with_crpr)    | Gitlab::Access::OWNER      | 'my-scope/my-container-stage-sha-1234' | false
        ref(:project_with_crpr)    | Gitlab::Access::ADMIN      | 'my-scope/my-container-stage-sha-1234' | false

        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | 'my-scope/my-container-prod-sha-1234'  | true
        ref(:project_with_crpr)    | Gitlab::Access::MAINTAINER | 'my-scope/my-container-prod-sha-1234'  | true
        ref(:project_with_crpr)    | Gitlab::Access::OWNER      | 'my-scope/my-container-prod-sha-1234'  | false
        ref(:project_with_crpr)    | Gitlab::Access::ADMIN      | 'my-scope/my-container-prod-sha-1234'  | false

        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | 'my-scope/my-container-release-v1'     | true
        ref(:project_with_crpr)    | Gitlab::Access::OWNER      | 'my-scope/my-container-release-v1'     | true
        ref(:project_with_crpr)    | Gitlab::Access::ADMIN      | 'my-scope/my-container-release-v1'     | false

        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | 'my-scope/my-container-any-suffix'     | true
        ref(:project_with_crpr)    | Gitlab::Access::MAINTAINER | 'my-scope/my-container-any-suffix'     | false
        ref(:project_with_crpr)    | Gitlab::Access::OWNER      | 'my-scope/my-container-any-suffix'     | false

        # For non-matching repository_path
        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | 'my-scope/non-matching-container'      | false

        # For no access level
        ref(:project_with_crpr)    | Gitlab::Access::NO_ACCESS  | 'my-scope/my-container-prod-sha-1234'  | true

        # Edge cases
        ref(:project_with_crpr)    | 0                          | ''                                     | false
        ref(:project_with_crpr)    | nil                        | nil                                    | false
        ref(:project_with_crpr)    | Gitlab::Access::DEVELOPER  | nil                                    | false
        ref(:project_with_crpr)    | nil                        | 'my-scope/non-matching-container'      | false

        # For projects that have no container registry protection rules
        ref(:project_without_crpr) | Gitlab::Access::DEVELOPER  | 'my-scope/my-container-prod-sha-1234'  | false
        ref(:project_without_crpr) | Gitlab::Access::MAINTAINER | 'my-scope/my-container-prod-sha-1234'  | false
        ref(:project_without_crpr) | Gitlab::Access::OWNER      | 'my-scope/my-container-prod-sha-1234'  | false
      end

      with_them do
        it { is_expected.to eq push_protected }
      end
    end
  end
end

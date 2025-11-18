# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the packages protection rule', :aggregate_failures, feature_category: :package_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:package_protection_rule) do
    create(:package_protection_rule, project: project, minimum_access_level_for_push: :maintainer)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:package_protection_rule_attributes) { build_stubbed(:package_protection_rule, project: project) }

  let(:mutation) do
    graphql_mutation(:update_packages_protection_rule, input,
      <<~QUERY
      packageProtectionRule {
        packageNamePattern
        minimumAccessLevelForDelete
        minimumAccessLevelForPush
      }
      clientMutationId
      errors
      QUERY
    )
  end

  let(:input) do
    {
      id: package_protection_rule.to_global_id,
      package_name_pattern: "#{package_protection_rule.package_name_pattern}-updated",
      minimum_access_level_for_delete: 'ADMIN',
      minimum_access_level_for_push: 'MAINTAINER'
    }
  end

  let(:mutation_response) { graphql_mutation_response(:update_packages_protection_rule) }
  let(:mutation_response_errors) { mutation_response['errors'] }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'a successful response' do
    it { subject.tap { expect_graphql_errors_to_be_empty } }

    it 'returns the updated package protection rule' do
      subject

      expect(mutation_response).to include(
        'packageProtectionRule' => {
          'packageNamePattern' => expected_attributes[:package_name_pattern],
          'minimumAccessLevelForDelete' => expected_attributes[:minimum_access_level_for_delete]&.upcase,
          'minimumAccessLevelForPush' => expected_attributes[:minimum_access_level_for_push]&.upcase
        }
      )
    end

    it 'updates attributes of existing package protection rule' do
      expect { subject }.not_to change { ::Packages::Protection::Rule.count }

      expect(package_protection_rule.reload).to have_attributes(
        package_name_pattern: expected_attributes[:package_name_pattern],
        minimum_access_level_for_delete: expected_attributes[:minimum_access_level_for_delete]&.downcase,
        minimum_access_level_for_push: expected_attributes[:minimum_access_level_for_push]&.downcase
      )
    end
  end

  shared_examples 'an erroneous response' do
    it { subject.tap { expect(mutation_response).to be_blank } }
    it { expect { subject }.not_to change { package_protection_rule.reload.updated_at } }
  end

  it_behaves_like 'a successful response' do
    let(:expected_attributes) { input }
  end

  context 'when feature flag `packages_protected_packages_delete` is disabled' do
    before do
      package_protection_rule.update!(minimum_access_level_for_delete: nil)

      stub_feature_flags(packages_protected_packages_delete: false)
    end

    it_behaves_like 'a successful response' do
      let(:expected_attributes) do
        input.merge(minimum_access_level_for_delete: package_protection_rule.minimum_access_level_for_delete)
      end
    end

    context 'when minimum_access_level_for_push is nil' do
      let(:input) { super().merge(minimum_access_level_for_push: nil) }

      it 'includes error message in response' do
        is_expected.tap do
          expect(mutation_response_errors).to include(/at least a minimum access role for push or delete/)
        end
      end
    end
  end

  context 'with other existing package protection rule with same package_name_pattern' do
    let_it_be_with_reload(:other_existing_package_protection_rule) do
      create(:package_protection_rule, project: project,
        package_name_pattern: "#{package_protection_rule.package_name_pattern}-other")
    end

    let(:input) { super().merge(package_name_pattern: other_existing_package_protection_rule.package_name_pattern) }

    it { is_expected.tap { expect_graphql_errors_to_be_empty } }

    it 'returns a blank package protection rule' do
      is_expected.tap { expect(mutation_response['packageProtectionRule']).to be_blank }
    end

    it 'includes error message in response' do
      is_expected.tap { expect(mutation_response_errors).to eq ['Package name pattern has already been taken'] }
    end
  end

  context 'with invalid input param `minimumAccessLevelForPush`' do
    let(:input) { super().merge(minimum_access_level_for_push: 'INVALID_ACCESS_LEVEL') }

    it { is_expected.tap { expect_graphql_errors_to_include(/invalid value for minimumAccessLevelForPush/) } }
  end

  context 'with invalid input param `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_delete: 'INVALID_ACCESS_LEVEL') }

    it { is_expected.tap { expect_graphql_errors_to_include(/invalid value for minimumAccessLevelForDelete/) } }
  end

  context 'with invalid input param `packageNamePattern`' do
    let(:input) { super().merge(package_name_pattern: '') }

    it_behaves_like 'an erroneous response'

    it { is_expected.tap { expect_graphql_errors_to_include(/packageNamePattern can't be blank/) } }
  end

  context 'with blank input fields `minimumAccessLevelForPush` and `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_push: nil, minimum_access_level_for_delete: nil) }

    it 'includes error message in response' do
      is_expected.tap do
        expect(mutation_response_errors).to include(/at least a minimum access role for push or delete/)
      end
    end
  end

  context 'with standalone package name pattern' do
    let(:input) { super().merge(package_name_pattern: '*') }

    it_behaves_like 'a successful response' do
      let(:expected_attributes) do
        input
      end
    end

    it 'updates the package protection rule to wildcard pattern' do
      is_expected.tap do
        expect(mutation_response['packageProtectionRule']['packageNamePattern']).to eq('*')
      end
    end
  end

  context 'when current_user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:current_user) do
      [ref(:developer), ref(:reporter), ref(:guest), ref(:anonymous)]
    end

    with_them do
      it { is_expected.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
    end
  end
end

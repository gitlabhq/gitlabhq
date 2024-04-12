# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the packages protection rule', :aggregate_failures, feature_category: :package_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:package_protection_rule) do
    create(:package_protection_rule, project: project, push_protected_up_to_access_level: :developer)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:package_protection_rule_attributes) { build_stubbed(:package_protection_rule, project: project) }

  let(:mutation) do
    graphql_mutation(:update_packages_protection_rule, input,
      <<~QUERY
      packageProtectionRule {
        packageNamePattern
        pushProtectedUpToAccessLevel
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
      push_protected_up_to_access_level: 'MAINTAINER'
    }
  end

  let(:mutation_response) { graphql_mutation_response(:update_packages_protection_rule) }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'a successful response' do
    it { subject.tap { expect_graphql_errors_to_be_empty } }

    it 'returns the updated package protection rule' do
      subject

      expect(mutation_response).to include(
        'packageProtectionRule' => {
          'packageNamePattern' => input[:package_name_pattern],
          'pushProtectedUpToAccessLevel' => input[:push_protected_up_to_access_level]
        }
      )
    end

    it do
      subject.tap do
        expect(package_protection_rule.reload).to have_attributes(
          package_name_pattern: input[:package_name_pattern],
          push_protected_up_to_access_level: input[:push_protected_up_to_access_level].downcase
        )
      end
    end
  end

  shared_examples 'an erroneous response' do
    it { subject.tap { expect(mutation_response).to be_blank } }
    it { expect { subject }.not_to change { package_protection_rule.reload.updated_at } }
  end

  it_behaves_like 'a successful response'

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
      is_expected.tap { expect(mutation_response['errors']).to eq ['Package name pattern has already been taken'] }
    end
  end

  context 'with invalid input param `pushProtectedUpToAccessLevel`' do
    let(:input) { super().merge(push_protected_up_to_access_level: nil) }

    it_behaves_like 'an erroneous response'

    it { is_expected.tap { expect_graphql_errors_to_include(/pushProtectedUpToAccessLevel can't be blank/) } }
  end

  context 'with invalid input param `packageNamePattern`' do
    let(:input) { super().merge(package_name_pattern: '') }

    it_behaves_like 'an erroneous response'

    it { is_expected.tap { expect_graphql_errors_to_include(/packageNamePattern can't be blank/) } }
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

  context "when feature flag ':packages_protected_packages' disabled" do
    before do
      stub_feature_flags(packages_protected_packages: false)
    end

    it_behaves_like 'an erroneous response'

    it 'returns error of disabled feature flag' do
      is_expected.tap { expect_graphql_errors_to_include(/'packages_protected_packages' feature flag is disabled/) }
    end
  end
end

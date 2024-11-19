# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a package protection rule', :aggregate_failures, feature_category: :package_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_refind(:package_protection_rule) { create(:package_protection_rule, project: project) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:mutation) { graphql_mutation(:delete_packages_protection_rule, input) }
  let(:mutation_response) { graphql_mutation_response(:delete_packages_protection_rule) }
  let(:input) { { id: package_protection_rule.to_global_id } }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'an erroneous response' do
    it { subject.tap { expect(mutation_response).to be_blank } }
    it { expect { subject }.not_to change { ::Packages::Protection::Rule.count } }
  end

  it_behaves_like 'a working GraphQL mutation'

  it 'responds with deleted package protection rule' do
    subject

    expect(mutation_response).to include(
      'errors' => be_blank,
      'packageProtectionRule' => {
        'id' => package_protection_rule.to_global_id.to_s,
        'packageNamePattern' => package_protection_rule.package_name_pattern,
        'packageType' => package_protection_rule.package_type.upcase,
        'minimumAccessLevelForPush' => package_protection_rule.minimum_access_level_for_push.upcase
      }
    )
  end

  it { is_expected.tap { expect_graphql_errors_to_be_empty } }
  it { expect { subject }.to change { ::Packages::Protection::Rule.count }.from(1).to(0) }

  context 'with existing package protection rule belonging to other project' do
    let_it_be(:package_protection_rule) do
      create(:package_protection_rule, package_name_pattern: 'protection_rule_other_project')
    end

    it_behaves_like 'an erroneous response'

    it { subject.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
  end

  context 'with deleted package protection rule' do
    let!(:package_protection_rule) do
      create(:package_protection_rule, project: project, package_name_pattern: 'protection_rule_deleted').destroy!
    end

    it_behaves_like 'an erroneous response'

    it { subject.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
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
      it_behaves_like 'an erroneous response'

      it { subject.tap { expect_graphql_errors_to_include(/you don't have permission to perform this action/) } }
    end
  end
end

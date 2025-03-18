# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Protection::CheckDeleteRuleExistenceService, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:unauthorized_user) { create(:user) }
  let_it_be(:project_developer) { create(:user, developer_of: project) }
  let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:project_owner) { project.owner }
  let_it_be(:instance_admin) { create(:admin) }

  let_it_be(:container_protection_rule_npm) do
    create(:package_protection_rule,
      project: project,
      package_type: :npm,
      package_name_pattern: "@#{project.full_path}*",
      minimum_access_level_for_delete: :owner)
  end

  let_it_be(:container_protection_rule_pypi) do
    create(:package_protection_rule,
      project: project,
      package_type: :pypi,
      package_name_pattern: "#{project.full_path}*",
      minimum_access_level_for_delete: :admin)
  end

  let(:params) { { package_name: package_name, package_type: package_type } }
  let(:service) { described_class.new(project: project, current_user: current_user, params: params) }

  subject(:service_response) { service.execute }

  shared_examples 'a service response for protection rule exists' do
    it_behaves_like 'returning a success service response'
    it { is_expected.to have_attributes(payload: { protection_rule_exists?: true }) }
  end

  shared_examples 'a service response for protection rule does not exist' do
    it_behaves_like 'returning a success service response'
    it { is_expected.to have_attributes(payload: { protection_rule_exists?: false }) }
  end

  shared_examples 'an error service response for unauthorized actor' do
    it_behaves_like 'returning an error service response', message: 'Unauthorized'
    it { is_expected.to have_attributes reason: :unauthorized }
  end

  shared_examples 'an error service response for invalid package type' do
    it_behaves_like 'returning an error service response', message: 'Invalid package type'
    it { is_expected.to have_attributes reason: :invalid_package_type }
  end

  describe '#execute', :enable_admin_mode do
    # rubocop:disable Layout/LineLength -- Avoid formatting in favor of one-line table syntax
    where(:package_name, :package_type, :current_user, :expected_shared_example) do
      lazy { "@#{project.full_path}" }             | :npm     | ref(:project_developer)  | 'an error service response for unauthorized actor'
      lazy { "@#{project.full_path}" }             | :npm     | ref(:project_maintainer) | 'a service response for protection rule exists'
      lazy { "@#{project.full_path}" }             | :npm     | ref(:project_owner)      | 'a service response for protection rule does not exist'
      lazy { "@#{project.full_path}" }             | :npm     | ref(:instance_admin)     | 'a service response for protection rule does not exist'
      lazy { "@other-scope/#{project.full_path}" } | :npm     | ref(:project_maintainer) | 'a service response for protection rule does not exist'
      lazy { "@other-scope/#{project.full_path}" } | :npm     | ref(:project_owner)      | 'a service response for protection rule does not exist'
      lazy { project.full_path }                   | :pypi    | ref(:project_maintainer) | 'a service response for protection rule exists'
      lazy { project.full_path }                   | :pypi    | ref(:project_owner)      | 'a service response for protection rule exists'
      lazy { project.full_path }                   | :pypi    | ref(:instance_admin)     | 'a service response for protection rule does not exist'

      # Edge cases
      lazy { "@#{project.full_path}" }             | :npm     | ref(:unauthorized_user)  | 'an error service response for unauthorized actor'
      lazy { "@#{project.full_path}" }             | :npm     | nil                      | 'an error service response for unauthorized actor'
      lazy { "@#{project.full_path}" }             | :no_type | nil                      | 'an error service response for invalid package type'
      lazy { "@#{project.full_path}" }             | nil      | ref(:project_owner)      | 'an error service response for invalid package type'
      nil                                          | :npm     | ref(:project_owner)      | 'a service response for protection rule does not exist'
      nil                                          | nil      | ref(:project_owner)      | 'an error service response for invalid package type'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it_behaves_like params[:expected_shared_example]
    end
  end
end

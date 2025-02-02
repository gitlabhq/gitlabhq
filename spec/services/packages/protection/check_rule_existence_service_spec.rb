# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Protection::CheckRuleExistenceService, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:project_developer) { create(:user, developer_of: project) }
  let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:project_owner) { project.owner }

  let_it_be(:package_name) { "@#{project.full_path}" }
  let_it_be(:package_type) { :npm }

  let(:current_user) { project_owner }
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

  describe '#execute' do
    let_it_be(:package_protection_rule_npm) do
      create(:package_protection_rule,
        project: project,
        package_type: :npm,
        package_name_pattern: "#{package_name}*",
        minimum_access_level_for_push: :maintainer)
    end

    let_it_be(:package_protection_rule_pypi) do
      create(:package_protection_rule,
        project: project,
        package_type: :pypi,
        package_name_pattern: package_name,
        minimum_access_level_for_push: :maintainer)
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting in favor of one-line table syntax
    where(:package_name, :package_type, :current_user, :expected_shared_example) do
      lazy { "@#{project.full_path}" }             | :npm          | ref(:project_developer) | 'a service response for protection rule exists'
      lazy { "@#{project.full_path}" }             | :npm          | ref(:project_owner)     | 'a service response for protection rule does not exist'

      lazy { "@#{project.full_path}" }             | :pypi         | ref(:project_developer) | 'a service response for protection rule exists'
      lazy { "@#{project.full_path}" }             | :pypi         | ref(:project_owner)     | 'a service response for protection rule does not exist'

      lazy { "@other-scope/#{project.full_path}" } | :npm          | ref(:project_developer) | 'a service response for protection rule does not exist'
      lazy { "@other-scope/#{project.full_path}" } | :npm          | ref(:project_owner)     | 'a service response for protection rule does not exist'

      # Edge cases
      lazy { "@#{project.full_path}" }             | :npm          | nil                     | 'an error service response for unauthorized actor'
      lazy { "@#{project.full_path}" }             | :invalid_type | nil                     | 'an error service response for invalid package type'
      lazy { "@#{project.full_path}" }             | nil           | ref(:project_developer) | 'an error service response for invalid package type'
      nil                                          | :npm          | ref(:project_developer) | 'a service response for protection rule does not exist'
      nil                                          | nil           | ref(:project_developer) | 'an error service response for invalid package type'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it_behaves_like params[:expected_shared_example]
    end

    context 'with deploy token' do
      let_it_be(:deploy_token_for_project) { create(:deploy_token, :all_scopes, projects: [project]) }
      let_it_be(:deploy_token_for_other_project) { create(:deploy_token, :all_scopes) }

      # rubocop:disable Layout/LineLength -- Avoid formatting in favor of one-line table syntax
      where(:package_name, :package_type, :current_user, :expected_shared_example) do
        lazy { "@#{project.full_path}" }             | :npm          | ref(:deploy_token_for_project)       | 'a service response for protection rule exists'
        lazy { "@#{project.full_path}" }             | :pypi         | ref(:deploy_token_for_project)       | 'a service response for protection rule exists'

        lazy { "@other-scope-#{project.full_path}" } | :npm          | ref(:deploy_token_for_project)       | 'a service response for protection rule does not exist'
        lazy { "@other-scope-#{project.full_path}" } | :pypi         | ref(:deploy_token_for_project)       | 'a service response for protection rule does not exist'

        lazy { "@#{project.full_path}" }             | :npm          | ref(:deploy_token_for_other_project) | 'an error service response for unauthorized actor'

        # Edge cases
        lazy { "@#{project.full_path}" }             | :npm          | nil                                  | 'an error service response for unauthorized actor'
        lazy { "@#{project.full_path}" }             | :invalid_type | ref(:deploy_token_for_project)       | 'an error service response for invalid package type'
        lazy { "@#{project.full_path}" }             | nil           | ref(:deploy_token_for_project)       | 'an error service response for invalid package type'
        nil                                          | :npm          | ref(:deploy_token_for_project)       | 'a service response for protection rule does not exist'
        nil                                          | nil           | ref(:deploy_token_for_project)       | 'an error service response for invalid package type'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it_behaves_like params[:expected_shared_example]
      end
    end

    context 'with admin user', :enable_admin_mode do
      let_it_be(:instance_admin) { create(:admin) }
      let_it_be(:project_admin) { create(:admin, owner_of: project) }

      where(:current_user) do
        [
          ref(:instance_admin),
          ref(:project_admin)
        ]
      end

      with_them do
        it_behaves_like 'a service response for protection rule does not exist'
      end
    end

    context 'for unexpected error cases' do
      let(:current_user) { Object.new }

      before do
        allow(service).to receive(:can?).and_return(true)
      end

      it 'raises an error' do
        expect { service_response }.to raise_error(ArgumentError, "Invalid user")
      end
    end
  end
end

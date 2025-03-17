# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::CheckRuleExistenceService, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:unauthorized_user) { create(:user) }
  let_it_be(:project_developer) { create(:user, developer_of: project) }
  let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:project_owner) { project.owner }
  let_it_be(:instance_admin) { create(:admin) }

  let_it_be(:project_deploy_token) { create(:deploy_token, :all_scopes, projects: [project]) }
  let_it_be(:other_deploy_token) { create(:deploy_token, :all_scopes) }

  let_it_be(:container_registry_protection_rule) do
    create(:container_registry_protection_rule,
      project: project,
      repository_path_pattern: "#{project.full_path}/protected*",
      minimum_access_level_for_push: :owner,
      minimum_access_level_for_delete: :admin)
  end

  let(:params) { { repository_path: repository_path_pattern, action: action } }

  let(:service) { described_class.new(project: project, current_user: current_user, params: params) }

  subject(:service_response) { service.execute }

  shared_examples 'protection rule exists' do
    it_behaves_like 'returning a success service response'
    it { is_expected.to have_attributes(payload: { protection_rule_exists?: true }) }
  end

  shared_examples 'protection rule does not exist' do
    it_behaves_like 'returning a success service response'
    it { is_expected.to have_attributes(payload: { protection_rule_exists?: false }) }
  end

  shared_examples 'error response for unauthorized actor' do
    it_behaves_like 'returning an error service response', message: 'Unauthorized'
    it { is_expected.to have_attributes reason: :unauthorized }
  end

  shared_examples 'raising an error for invalid param :action' do
    it 'raises an error' do
      expect { service_response }.to raise_error(ArgumentError, 'Invalid param :action')
    end
  end

  describe '#execute', :enable_admin_mode do
    # rubocop:disable Layout/LineLength -- Avoid formatting to ensure one-line table syntax
    where(:action, :repository_path_pattern, :current_user, :expected_shared_example) do
      :push   | lazy { "#{project.full_path}/protected" }       | ref(:project_developer)    | 'protection rule exists'
      :push   | lazy { "#{project.full_path}/protected" }       | ref(:project_maintainer)   | 'protection rule exists'
      :push   | lazy { "#{project.full_path}/protected" }       | ref(:project_owner)        | 'protection rule does not exist'
      :push   | lazy { "#{project.full_path}/protected" }       | ref(:instance_admin)       | 'protection rule does not exist'
      :push   | lazy { "#{project.full_path}/protected" }       | ref(:project_deploy_token) | 'protection rule exists'
      :push   | lazy { "#{project.full_path}/protected" }       | ref(:other_deploy_token)   | 'error response for unauthorized actor'

      :push   | lazy { "other/#{project.full_path}/protected" } | ref(:project_developer)    | 'protection rule does not exist'
      :push   | lazy { "other/#{project.full_path}/protected" } | ref(:project_owner)        | 'protection rule does not exist'
      :push   | lazy { "other/#{project.full_path}/protected" } | ref(:project_deploy_token) | 'protection rule does not exist'
      :push   | lazy { "other/#{project.full_path}/protected" } | ref(:instance_admin)       | 'protection rule does not exist'

      :delete | lazy { "#{project.full_path}/protected" }       | ref(:project_developer)    | 'protection rule exists'
      :delete | lazy { "#{project.full_path}/protected" }       | ref(:project_maintainer)   | 'protection rule exists'
      :delete | lazy { "#{project.full_path}/protected" }       | ref(:project_owner)        | 'protection rule exists'
      :delete | lazy { "#{project.full_path}/protected" }       | ref(:project_deploy_token) | 'error response for unauthorized actor'
      :delete | lazy { "#{project.full_path}/protected" }       | ref(:instance_admin)       | 'protection rule does not exist'

      :delete | lazy { "other/#{project.full_path}/protected" } | ref(:project_maintainer)   | 'protection rule does not exist'
      :delete | lazy { "other/#{project.full_path}/protected" } | ref(:project_owner)        | 'protection rule does not exist'
      :delete | lazy { "other/#{project.full_path}/protected" } | ref(:project_deploy_token) | 'error response for unauthorized actor'

      # # Edge cases
      :push   | lazy { "#{project.full_path}/protected" }       | ref(:unauthorized_user)    | 'error response for unauthorized actor'
      :push   | lazy { "#{project.full_path}/protected" }       | nil                        | 'error response for unauthorized actor'
      :push   | ''                                              | ref(:project_developer)    | 'protection rule does not exist'
      :push   | nil                                             | ref(:project_developer)    | 'protection rule does not exist'
      :delete | lazy { "#{project.full_path}/protected" }       | ref(:unauthorized_user)    | 'error response for unauthorized actor'
      :other  | lazy { "#{project.full_path}/protected" }       | ref(:project_developer)    | 'raising an error for invalid param :action'
      nil     | lazy { "#{project.full_path}/protected" }       | ref(:project_developer)    | 'raising an error for invalid param :action'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it_behaves_like params[:expected_shared_example]
    end

    context 'for unexpected current_user' do
      let(:current_user) { Object.new }
      let(:action) { :push }
      let(:repository_path_pattern) { "#{project.full_path}/protected" }

      before do
        allow(service).to receive(:can?).and_return(true)
      end

      it 'raises an error' do
        expect { service_response }.to raise_error(ArgumentError, "Invalid user")
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectPackagesProtectionRules, :aggregate_failures, feature_category: :package_registry do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be_with_reload(:protection_rule) { create(:package_protection_rule, project: project) }
  let_it_be(:protection_rule_id) { protection_rule.id }

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:invalid_token) { 'invalid-token123' }
  let_it_be(:headers_with_invalid_token) { { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => invalid_token } }

  let(:path) { 'packages/protection/rules' }
  let(:url) { "/projects/#{project.id}/#{path}" }

  let(:params) do
    {
      package_name_pattern: '@my-new-scope/my-package-*',
      package_type: protection_rule.package_type,
      minimum_access_level_for_delete: protection_rule.minimum_access_level_for_delete,
      minimum_access_level_for_push: protection_rule.minimum_access_level_for_push
    }
  end

  shared_examples 'rejecting project packages protection rules request when enough permissions' do
    it_behaves_like 'rejecting protection rules request when invalid project'
  end

  describe 'GET /projects/:id/packages/protection/rules' do
    let(:url) { "/projects/#{project.id}/packages/protection/rules" }

    subject(:get_package_rules) { get(api(url, api_user)) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      let_it_be(:other_package_protection_rule) do
        create(:package_protection_rule, project: project, package_name_pattern: "@my-scope/my-package-*")
      end

      it 'gets the package protection rules' do
        get_package_rules

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(2)
        expect(json_response).to include({
          'id' => protection_rule.id,
          'project_id' => protection_rule.project_id,
          'package_name_pattern' => protection_rule.package_name_pattern,
          'package_type' => protection_rule.package_type,
          'minimum_access_level_for_delete' => protection_rule.minimum_access_level_for_delete,
          'minimum_access_level_for_push' => protection_rule.minimum_access_level_for_push
        })
      end

      context 'when feature flag :packages_protected_packages_delete is disabled' do
        before do
          stub_feature_flags(packages_protected_packages_delete: false)
        end

        it 'gets the package protection rules without minimum_access_level_for_delete' do
          get_package_rules

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to all include('minimum_access_level_for_delete' => nil)
        end
      end

      it_behaves_like 'rejecting project packages protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:get_package_rules) { get(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'POST /projects/:id/packages/protection/rules' do
    let(:url) { "/projects/#{project.id}/packages/protection/rules" }

    subject(:post_package_rule) { post(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'creates a package protection rule' do
        expect { post_package_rule }.to change { Packages::Protection::Rule.count }.by(1)
        expect(response).to have_gitlab_http_status(:created)

        expect(json_response).to include(
          'id' => Integer,
          'project_id' => project.id,
          'package_name_pattern' => params[:package_name_pattern],
          'package_type' => params[:package_type],
          'minimum_access_level_for_delete' => params[:minimum_access_level_for_delete],
          'minimum_access_level_for_push' => params[:minimum_access_level_for_push]
        )
      end

      context 'when feature flag :packages_protected_packages_delete is disabled' do
        before do
          stub_feature_flags(packages_protected_packages_delete: false)
        end

        it 'creates a package protection rule with blank minimum_access_level_for_delete' do
          expect { post_package_rule }.to change { Packages::Protection::Rule.count }.by(1)
          expect(response).to have_gitlab_http_status(:created)

          expect(json_response).to include(
            'id' => Integer,
            'project_id' => project.id,
            'package_name_pattern' => params[:package_name_pattern],
            'package_type' => params[:package_type],
            'minimum_access_level_for_delete' => nil,
            'minimum_access_level_for_push' => params[:minimum_access_level_for_push]
          )

          expect(Packages::Protection::Rule.find(json_response['id']).minimum_access_level_for_delete).to be_nil
        end
      end

      context 'without minimum_access_level_for_delete' do
        let(:params) { super().except(:minimum_access_level_for_delete) }

        it 'creates a package protection rule' do
          expect { post_package_rule }.to change { Packages::Protection::Rule.count }.by(1)
          expect(response).to have_gitlab_http_status(:created)

          expect(json_response).to include(
            'id' => Integer,
            'project_id' => project.id,
            'package_name_pattern' => params[:package_name_pattern],
            'package_type' => params[:package_type],
            'minimum_access_level_for_delete' => nil,
            'minimum_access_level_for_push' => params[:minimum_access_level_for_push]
          )
        end
      end

      context 'with blank minimum_access_level_for_delete' do
        let(:params) { super().merge(minimum_access_level_for_delete: '') }

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to include 'error' => 'minimum_access_level_for_delete does not have a valid value'
        end
      end

      context 'with invalid package_type' do
        let(:params) { super().merge(package_type: 'not in enum') }

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to include 'error' => 'package_type does not have a valid value'
        end
      end

      context 'with invalid minimum_access_level_for_push' do
        let(:params) { super().merge(minimum_access_level_for_push: 'not in enum') }

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'without minimum_access_levels' do
        let(:params) { super().except(:minimum_access_level_for_push, :minimum_access_level_for_delete) }

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to include(
            'error' => 'minimum_access_level_for_push, minimum_access_level_for_delete are missing, ' \
              'at least one parameter must be provided'
          )
        end
      end

      context 'with invalid minimum_access_levels' do
        let(:params) { super().merge(minimum_access_level_for_push: nil, minimum_access_level_for_delete: nil) }

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'with already existing package_name_pattern' do
        let(:params) { super().merge(package_name_pattern: protection_rule.package_name_pattern) }

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      it_behaves_like 'rejecting project packages protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:post_package_rules) { post(api(url), headers: headers_with_invalid_token, params: params) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'PATCH /projects/:id/packages/protection/rules/:package_protection_rule_id' do
    let(:path) { "packages/protection/rules/#{protection_rule_id}" }

    subject(:patch_package_rule) { patch(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }
      let_it_be(:changed_scope) { '@my-changed-scope/my-package-*' }

      context 'with full changeset' do
        let(:params) { super().merge(package_name_pattern: changed_scope) }

        it 'updates a package protection rule' do
          patch_package_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["package_name_pattern"]).to eq(changed_scope)
          expect(json_response["package_type"]).to eq(protection_rule.package_type)
        end
      end

      context 'with a single change' do
        let(:params) { { package_name_pattern: changed_scope } }

        it 'updates a package protection rule' do
          patch_package_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["package_name_pattern"]).to eq(changed_scope)
        end
      end

      context 'with changing minimum_access_level_for_delete' do
        let(:params) { super().merge(minimum_access_level_for_delete: 'admin') }

        it 'updates a package protection rule' do
          patch_package_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["minimum_access_level_for_delete"]).to eq('admin')
        end

        context 'when feature flag :packages_protected_packages_delete is disabled' do
          before do
            stub_feature_flags(packages_protected_packages_delete: false)
          end

          it 'keeps old value for minimum_access_level_for_delete' do
            expect { patch_package_rule }.to not_change { protection_rule.reload.minimum_access_level_for_delete }

            expect(response).to have_gitlab_http_status(:ok)

            expect(json_response["minimum_access_level_for_delete"]).to be_nil
          end
        end
      end

      context 'with nil value for minimum_access_level_for_delete' do
        let(:params) { super().merge(minimum_access_level_for_delete: nil) }

        it 'updates a package protection rule' do
          patch_package_rule

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response["minimum_access_level_for_delete"]).to be_nil
        end
      end

      context 'with invalid package_type' do
        let(:params) { super().merge(package_type: 'not in enum') }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with invalid minimum_access_level_for_push' do
        let(:params) { super().merge(minimum_access_level_for_push: 'not in enum') }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with blank minimum_access_level_for_delete' do
        let(:params) { super().merge(minimum_access_level_for_delete: '') }

        it_behaves_like 'returning response status', :bad_request

        it 'returns error message' do
          expect { patch_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(json_response).to include 'error' => 'minimum_access_level_for_delete does not have a valid value'
        end
      end

      context 'with invalid minimum_access_levels' do
        let(:params) { super().merge(minimum_access_level_for_push: nil, minimum_access_level_for_delete: nil) }

        it_behaves_like 'returning response status', :unprocessable_entity
      end

      context 'with already existing package_name_pattern' do
        let_it_be(:existing_package_protection_rule) do
          create(:package_protection_rule, project: project, package_name_pattern: '@my-scope/my-package-*')
        end

        let(:params) { super().merge(package_name_pattern: existing_package_protection_rule.package_name_pattern) }

        it_behaves_like 'returning response status', :unprocessable_entity
      end

      it_behaves_like 'rejecting protection rules request when handling rule ids'
      it_behaves_like 'rejecting project packages protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:patch_package_rules) { patch(api(url), headers: headers_with_invalid_token, params: params) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'DELETE /projects/:id/packages/protection/rules/:package_protection_rule_id' do
    let(:path) { "packages/protection/rules/#{protection_rule_id}" }

    subject(:destroy_package_rule) { delete(api(url, api_user)) }

    it_behaves_like 'rejecting project protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'deletes the package protection rule' do
        destroy_package_rule
        expect { Packages::Protection::Rule.find(protection_rule.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like 'rejecting protection rules request when handling rule ids'
      it_behaves_like 'rejecting project packages protection rules request when enough permissions'
    end

    context 'with invalid token' do
      subject(:delete_package_rules) { delete(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end

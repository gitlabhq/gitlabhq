# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::PackagesHelpers, feature_category: :package_registry do
  let_it_be(:helper) { Class.new.include(API::Helpers).include(described_class).new }
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:package) { create(:generic_package) }

  describe 'authorize_packages_access!' do
    subject { helper.authorize_packages_access!(project) }

    it 'authorizes packages access' do
      expect(helper).to receive(:require_packages_enabled!)
      expect(helper).to receive(:authorize_read_package!).with(project)

      expect(subject).to eq nil
    end

    context 'with an allowed required permission' do
      subject { helper.authorize_packages_access!(project, :read_group) }

      it 'authorizes packages access' do
        expect(helper).to receive(:require_packages_enabled!)
        expect(helper).not_to receive(:authorize_read_package!)
        expect(helper).to receive(:authorize!).with(:read_group, project)

        expect(subject).to eq nil
      end
    end

    context 'with a not allowed permission' do
      subject { helper.authorize_packages_access!(project, :read_permission) }

      it 'rejects packages access' do
        expect(helper).to receive(:require_packages_enabled!)
        expect(helper).not_to receive(:authorize_read_package!)
        expect(helper).not_to receive(:authorize!).with(:test_permission, project)
        expect(helper).to receive(:forbidden!)

        expect(subject).to eq nil
      end
    end

    context 'with read_public_package_registry permission' do
      subject { helper.authorize_packages_access!(group, :read_package_within_public_registries) }

      it 'authorizes packages access' do
        expect(helper).to receive(:require_packages_enabled!)
        expect(helper).to receive(:authorize!).with(:read_package_within_public_registries, instance_of(::Packages::Policies::Group))

        expect(subject).to eq nil
      end
    end
  end

  describe 'authorize_read_package!' do
    using RSpec::Parameterized::TableSyntax

    where(:subject, :expected_class) do
      ref(:project) | ::Packages::Policies::Project
      ref(:group)   | ::Packages::Policies::Group
      ref(:package) | ::Packages::Generic::Package
    end

    with_them do
      it 'calls authorize! with correct subject' do
        expect(helper).to receive(:authorize!).with(:read_package, have_attributes(id: subject.id, class: expected_class))

        expect(helper.send(:authorize_read_package!, subject)).to eq nil
      end
    end
  end

  %i[create_package destroy_package admin_package].each do |action|
    describe "authorize_#{action}!" do
      subject { helper.send("authorize_#{action}!", project) }

      it 'calls authorize!' do
        expect(helper).to receive(:authorize!).with(action, project)

        expect(subject).to eq nil
      end
    end
  end

  describe 'require_packages_enabled!' do
    let(:packages_enabled) { true }

    subject { helper.require_packages_enabled! }

    before do
      allow(::Gitlab.config.packages).to receive(:enabled).and_return(packages_enabled)
    end

    context 'with packages enabled' do
      it "doesn't call not_found!" do
        expect(helper).not_to receive(:not_found!)

        expect(subject).to eq nil
      end
    end

    context 'with package disabled' do
      let(:packages_enabled) { false }

      it 'calls not_found!' do
        expect(helper).to receive(:not_found!).once

        subject
      end
    end
  end

  describe '#authorize_workhorse!' do
    let_it_be(:headers) { { 'HTTP_GITLAB_WORKHORSE' => 1 } }
    let_it_be(:params) { { subject: project } }

    let(:env) { headers }
    let(:request) { ActionDispatch::Request.new(env) }

    subject { helper.authorize_workhorse!(**params) }

    shared_examples 'workhorse authorize' do
      before do
        allow(helper).to receive(:request).and_return(request)
        allow(helper).to receive(:env).and_return(env)
      end

      it 'authorizes workhorse' do
        expect(helper).to receive(:authorize_create_package!).with(project)
        expect(helper).to receive(:status).with(200)
        expect(helper).to receive(:content_type).with(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        expect(Gitlab::Workhorse).to receive(:verify_api_request!).with(request.headers)
        expect(::Packages::PackageFileUploader).to receive(:workhorse_authorize).with(workhorse_authorize_params)

        expect(subject).to eq nil
      end
    end

    before do
      allow(helper).to receive(:headers).and_return(headers)
    end

    it_behaves_like 'workhorse authorize' do
      let(:workhorse_authorize_params) { { has_length: true, use_final_store_path: false } }
    end

    context 'without length' do
      let(:params) { super().merge(has_length: false) }

      it_behaves_like 'workhorse authorize' do
        let(:workhorse_authorize_params) do
          { has_length: false, maximum_size: ::API::Helpers::PackagesHelpers::MAX_PACKAGE_FILE_SIZE, use_final_store_path: false }
        end
      end
    end

    context 'when use_final_store_path is true' do
      let(:params) { super().merge(use_final_store_path: true) }

      it_behaves_like 'workhorse authorize' do
        let(:workhorse_authorize_params) { { has_length: true, use_final_store_path: true, final_store_path_config: { root_hash: project.id } } }
      end
    end
  end

  describe '#authorize_upload!' do
    subject { helper.authorize_upload!(project) }

    it 'authorizes the upload' do
      expect(helper).to receive(:authorize_create_package!).with(project)
      expect(helper).to receive(:require_gitlab_workhorse!)

      expect(subject).to eq nil
    end
  end

  describe '#user_project' do
    before do
      allow(helper).to receive(:params).and_return(id: project.id)
    end

    it 'calls find_project! on default action' do
      expect(helper).to receive(:find_project!)

      helper.user_project
    end

    it 'calls find_project! on read_project action' do
      expect(helper).to receive(:find_project!)

      helper.user_project(action: :read_project)
    end

    it 'calls user_project_with_read_package on read_package action' do
      expect(helper).to receive(:user_project_with_read_package)

      helper.user_project(action: :read_package)
    end

    it 'throws ArgumentError on unexpected action' do
      expect { helper.user_project(action: :other_action) }.to raise_error(ArgumentError, 'unexpected action: other_action')
    end
  end

  describe '#user_project_with_read_package' do
    before do
      helper.clear_memoization(:user_project_with_read_package)

      allow(helper).to receive(:params).and_return(id: params_id)
      allow(helper).to receive(:route_authentication_setting).and_return({ authenticate_non_public: true })
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:initial_current_user).and_return(user)
    end

    subject { helper.user_project_with_read_package }

    context 'with non-existing project' do
      let_it_be(:params_id) { non_existing_record_id }

      context 'with current user' do
        let_it_be(:user) { create(:user) }

        it 'returns Not Found' do
          expect(helper).to receive(:render_api_error!).with('404 Project Not Found', 404)

          is_expected.to be_nil
        end
      end

      context 'without current user' do
        let_it_be(:user) { nil }

        it 'returns Unauthorized' do
          expect(helper).to receive(:render_api_error!).with('401 Unauthorized', 401)

          is_expected.to be_nil
        end
      end
    end

    context 'with existing project' do
      let_it_be(:params_id) { project.id }

      context 'with current user' do
        let_it_be(:user) { create(:user) }

        context 'as developer member' do
          before do
            project.add_developer(user)
          end

          it 'returns project' do
            is_expected.to eq(project)
          end
        end

        context 'as guest member' do
          before do
            project.add_guest(user)
          end

          it 'returns project' do
            is_expected.to eq(project)
          end
        end
      end

      context 'without current user' do
        let_it_be(:user) { nil }

        it 'returns Unauthorized' do
          expect(helper).to receive(:render_api_error!).with('401 Unauthorized', 401)

          is_expected.to be_nil
        end
      end
    end

    context 'if no authorized project scope' do
      let_it_be(:params_id) { project.id }
      let_it_be(:user) { nil }

      it 'returns Forbidden' do
        expect(helper).to receive(:authorized_project_scope?).and_return(false)
        expect(helper).to receive(:render_api_error!).with('403 Forbidden', 403)

        is_expected.to be_nil
      end
    end
  end

  describe '#track_package_event' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it_behaves_like 'Snowplow event tracking with RedisHLL context' do
      let(:action) { 'push_package' }
      let(:scope) { :terraform_module }
      let(:category) { described_class.name }
      let(:namespace) { project.namespace }
      let(:user) { project.creator }
      let(:label) { 'redis_hll_counters.user_packages.user_packages_total_unique_counts_monthly' }
      let(:property) { 'i_package_terraform_module_user' }

      subject(:package_action) do
        args = { category: category, namespace: namespace, user: user, project: project }
        helper.track_package_event(action, scope, **args)
      end
    end

    context 'with internal event event' do
      let(:user) { project.creator }
      let(:category) { described_class.name }
      let(:namespace) { project.namespace }

      it 'calls internal events' do
        expect(Gitlab::InternalEvents).to receive(:track_event)
          .with('pull_package_from_registry',
            additional_properties: {
              label: 'terraform_module',
              property: 'user'
            },
            user: user,
            project: project,
            namespace: namespace
          )

        args = { category: category, user: user, project: project, namespace: namespace }
        helper.track_package_event('pull_package', :terraform_module, **args)
      end
    end

    context 'when using deploy token and action is push package' do
      let(:user) { create(:deploy_token, write_registry: true, projects: [project]) }
      let(:scope) { :rubygems }
      let(:category) { 'API::RubygemPackages' }
      let(:namespace) { project.namespace }
      let(:label) { 'counts.package_events_i_package_push_package_by_deploy_token' }
      let(:property) { 'i_package_push_package_by_deploy_token' }
      let(:service_ping_context) do
        [Gitlab::Tracking::ServicePingContext.new(data_source: :redis, event: 'package_pushed_using_deploy_token').to_h]
      end

      it 'logs a snowplow event' do
        args = { category: category, namespace: namespace, project: project }
        helper.track_package_event('push_package', scope, **args)

        expect_snowplow_event(
          category: category,
          action: 'push_package_by_deploy_token',
          context: service_ping_context,
          label: label,
          namespace: namespace,
          property: property,
          project: project,
          user: user
        )
      end
    end

    context 'when guest and action is pull package' do
      let(:user) { nil }
      let(:scope) { :rubygems }
      let(:category) { 'API::RubygemPackages' }
      let(:namespace) { project.namespace }
      let(:label) { 'counts.package_events_i_package_pull_package_by_guest' }
      let(:property) { 'i_package_pull_package_by_guest' }
      let(:service_ping_context) do
        [Gitlab::Tracking::ServicePingContext.new(data_source: :redis, event: 'package_pulled_by_guest').to_h]
      end

      it 'logs a snowplow event' do
        allow(helper).to receive(:current_user).and_return(nil)
        args = { category: category, namespace: namespace, project: project }
        helper.track_package_event('pull_package', scope, **args)

        expect_snowplow_event(
          category: category,
          action: 'pull_package_by_guest',
          context: service_ping_context,
          label: label,
          namespace: namespace,
          property: property,
          project: project
        )
      end
    end
  end
end

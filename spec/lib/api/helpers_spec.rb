# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  subject(:helper) { Class.new.include(described_class).new }

  describe '#current_user' do
    include Rack::Test::Methods

    let(:user) { build(:user, id: 42) }
    let(:helper) do
      Class.new(Grape::API::Instance) do
        helpers API::APIGuard::HelperMethods
        helpers API::Helpers
        format :json

        get 'user' do
          current_user ? { id: current_user.id } : { found: false }
        end

        get 'protected' do
          authenticate_by_gitlab_geo_node_token!
        end
      end
    end

    def app
      helper
    end

    it 'handles sticking when a user could be found' do
      allow_any_instance_of(described_class).to receive(:initial_current_user).and_return(user)

      expect(ApplicationRecord.sticking)
        .to receive(:find_caught_up_replica).with(:user, 42)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'id' => user.id })

      stick_object = last_request.env[::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT].first
      expect(stick_object[0]).to eq(User.sticking)
      expect(stick_object[1]).to eq(:user)
      expect(stick_object[2]).to eq(42)
    end

    it 'does not handle sticking if no user could be found' do
      allow_any_instance_of(described_class).to receive(:initial_current_user).and_return(nil)

      expect(ApplicationRecord.sticking)
        .not_to receive(:find_caught_up_replica)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'found' => false })
    end

    it 'returns the user if one could be found' do
      allow_any_instance_of(described_class).to receive(:initial_current_user).and_return(user)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'id' => user.id })
    end
  end

  describe '#find_project' do
    let(:project) { create(:project) }

    shared_examples 'project finder' do
      context 'when project exists' do
        it 'returns requested project' do
          expect(helper.find_project(existing_id)).to eq(project)
        end

        it 'returns nil' do
          expect(helper.find_project(non_existing_id)).to be_nil
        end
      end

      context 'when project id is not provided' do
        it 'returns nil' do
          expect(helper.find_project(nil)).to be_nil
        end
      end
    end

    context 'when ID is used as an argument' do
      let(:existing_id) { project.id }
      let(:non_existing_id) { non_existing_record_id }

      it_behaves_like 'project finder'
    end

    context 'when PATH is used as an argument' do
      let(:existing_id) { project.full_path }
      let(:non_existing_id) { 'something/else' }

      it_behaves_like 'project finder'

      context 'with an invalid PATH' do
        let(:non_existing_id) { 'undefined' } # path without slash

        it_behaves_like 'project finder'

        it 'does not hit the database' do
          expect(Project).not_to receive(:find_by_full_path)

          helper.find_project(non_existing_id)
        end
      end
    end

    context 'when ID is a negative number' do
      let(:existing_id) { project.id }
      let(:non_existing_id) { -1 }

      it_behaves_like 'project finder'
    end

    context 'when project is pending delete' do
      let(:project_pending_delete) { create(:project, pending_delete: true) }

      it 'does not return the project pending delete' do
        expect(Project).not_to receive(:find_by_full_path)

        expect(helper.find_project(project_pending_delete.id)).to be_nil
      end
    end

    context 'when project is hidden' do
      let(:hidden_project) { create(:project, :hidden) }

      it 'does not return the hidden project' do
        expect(Project).not_to receive(:find_by_full_path)

        expect(helper.find_project(hidden_project.id)).to be_nil
      end
    end
  end

  describe '#find_project!' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    shared_examples 'private project without access' do
      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      it 'returns not found' do
        expect(helper).to receive(:not_found!)

        helper.find_project!(project.id)
      end
    end

    context 'when user is authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:initial_current_user).and_return(user)
      end

      context 'public project' do
        it 'returns requested project' do
          expect(helper.find_project!(project.id)).to eq(project)
        end
      end

      context 'private project' do
        it_behaves_like 'private project without access'
      end

      # Container repository request is defined with job_token_scope = :project.
      context 'user authenticated with job token on container repository request' do
        let_it_be(:job) { create(:ci_build, project: project) }
        let_it_be(:outside_project) { create(:project) }

        before do
          allow(helper).to receive(:route_authentication_setting).and_return(job_token_scope: :project)
          allow(helper).to receive(:initial_current_user).and_return(user)
          helper.instance_variable_set(:@current_authenticated_job, job)
        end

        context "and requested project is not equal pipeline's project" do
          it 'returns forbidden' do
            expect(helper).to receive(:forbidden!).with("This project's CI/CD job token cannot be used to authenticate with the container registry of a different project.")

            helper.find_project!(outside_project.id)
          end
        end

        context "and requested project is equal pipeline's project" do
          it 'finds a project' do
            expect(helper.find_project!(project.id)).to eq(project)
          end
        end
      end

      # All API requests, except for the container repository route_authentication_settings[:job_token_scope], is empty.
      context 'user authenticated' do
        let_it_be(:job) { create(:ci_build, project: project) }
        let_it_be(:outside_project) { create(:project) }

        before do
          allow(helper).to receive(:route_authentication_setting).and_return(job_token_scope: nil)
          allow(helper).to receive(:initial_current_user).and_return(user)
          helper.instance_variable_set(:@current_authenticated_job, job)
        end

        context 'and user does not have permissions to read project' do
          before do
            allow(helper).to receive(:can?).with(user, :read_project, outside_project).and_return(false)
            allow(helper).to receive(:can?).with(user, :build_read_project, outside_project).and_return(false)
          end

          context 'with job token' do
            before do
              allow(user).to receive(:from_ci_job_token?).and_return(true)
              allow(user).to receive(:ci_job_token_scope).and_return(user.set_ci_job_token_scope!(job))
            end

            it 'returns forbidden' do
              expect(helper).to receive(:forbidden!).with("Authentication by CI/CD job token not allowed from #{project.path} to #{outside_project.path}.")

              helper.find_project!(outside_project.id)
            end

            context 'private project without access' do
              before do
                allow(helper).to receive(:authenticate_non_public?).and_return(true)
              end

              it 'returns unauthorized' do
                expect(helper).to receive(:unauthorized!)

                helper.find_project!(outside_project.id)
              end
            end
          end

          context 'without job token' do
            before do
              allow(user).to receive(:from_ci_job_token?).and_return(false)
            end

            it 'returns not_found' do
              expect(helper).to receive(:not_found!)

              helper.find_project!(outside_project.id)
            end
          end

          context 'without job token scope' do
            before do
              allow(user).to receive(:from_ci_job_token?).and_return(true)
              allow(user).to receive(:ci_job_token_scope).and_return(nil)
            end

            it 'returns not_found' do
              expect(helper).to receive(:not_found!)

              helper.find_project!(outside_project.id)
            end
          end
        end
      end

      context 'user is authenticated with a job token from another project and fine grained policies are enabled' do
        let_it_be(:runner_project) { create(:project) }
        let_it_be(:job) { create(:ci_build, project: runner_project) }
        let_it_be(:allowed_job_token_policy) { ::Ci::JobToken::Policies::POLICIES.first }
        let_it_be(:job_token_policy) { allowed_job_token_policy }

        before do
          create(:ci_job_token_project_scope_link,
            source_project: project,
            target_project: runner_project,
            direction: :inbound,
            job_token_policies: [allowed_job_token_policy],
            default_permissions: false
          )

          allow(helper).to receive(:route_authentication_setting).and_return({})
          allow(helper).to receive(:route_setting).with(:authorization).and_return(job_token_policies: job_token_policy)
          allow(user).to receive(:ci_job_token_scope).and_return(user.set_ci_job_token_scope!(job))
        end

        subject(:find_project!) { helper.find_project!(project.id) }

        it { is_expected.to eq project }

        context 'when the given policy is not allowed' do
          let_it_be(:job_token_policy) { :not_allowed_policy }

          it 'returns forbidden' do
            expect(helper)
              .to receive(:forbidden!)
              .with("Insufficient permissions to access this resource in project #{project.path}. " \
                'The following token permission is required: not_allowed_policy.')

            find_project!
          end

          context 'when multiple policies are required' do
            let_it_be(:job_token_policy) { [:policy_1, :policy_2] }

            it 'returns forbidden' do
              expect(helper)
                .to receive(:forbidden!)
                .with("Insufficient permissions to access this resource in project #{project.path}. " \
                  'The following token permissions are required: policy_1 and policy_2.')

              find_project!
            end
          end

          context 'when job token policies are skipped' do
            before do
              allow(helper).to receive(:route_setting).with(:authorization).and_return(skip_job_token_policies: true)
            end

            it { is_expected.to eq project }
          end

          context 'when the `add_policies_to_ci_job_token` feature flag is disabled' do
            before do
              stub_feature_flags(add_policies_to_ci_job_token: false)
            end

            it { is_expected.to eq project }
          end
        end

        context 'when no policy is given' do
          let_it_be(:job_token_policy) { nil }

          it 'returns forbidden' do
            expect(helper).to receive(:forbidden!).with('This action is unauthorized for CI/CD job tokens.')

            find_project!
          end

          context 'when the `add_policies_to_ci_job_token` feature flag is disabled' do
            before do
              stub_feature_flags(add_policies_to_ci_job_token: false)
            end

            it { is_expected.to eq project }
          end
        end

        context "when route settings don't exist" do
          before do
            allow(helper).to receive(:respond_to?).with(:route_setting).and_return(false)
          end

          it 'returns forbidden' do
            expect(helper).to receive(:forbidden!).with('This action is unauthorized for CI/CD job tokens.')

            find_project!
          end
        end
      end
    end

    context 'when user is not authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
        allow(helper).to receive(:initial_current_user).and_return(nil)
      end

      context 'public project' do
        it 'returns requested project' do
          expect(helper.find_project!(project.id)).to eq(project)
        end
      end

      context 'private project' do
        it_behaves_like 'private project without access'
      end
    end

    context 'support for IDs and paths as argument' do
      let_it_be(:project) { create(:project) }

      let(:user) { project.first_owner }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:authorized_project_scope?).and_return(true)
        allow(helper).to receive(:job_token_authentication?).and_return(false)
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      shared_examples 'project finder' do
        context 'when project exists' do
          it 'returns requested project' do
            expect(helper.find_project!(existing_id)).to eq(project)
          end

          it 'returns nil' do
            expect(helper).to receive(:render_api_error!).with('404 Project Not Found', 404)
            expect(helper.find_project!(non_existing_id)).to be_nil
          end
        end
      end

      context 'when ID is used as an argument' do
        let(:existing_id) { project.id }
        let(:non_existing_id) { non_existing_record_id }

        it_behaves_like 'project finder'
      end

      context 'when PATH is used as an argument' do
        let(:existing_id) { project.full_path }
        let(:non_existing_id) { 'something/else' }

        it_behaves_like 'project finder'

        context 'with an invalid PATH' do
          let(:non_existing_id) { 'undefined' } # path without slash

          it_behaves_like 'project finder'

          it 'does not hit the database' do
            expect(Project).not_to receive(:find_by_full_path)
            expect(helper).to receive(:render_api_error!).with('404 Project Not Found', 404)

            helper.find_project!(non_existing_id)
          end
        end
      end
    end
  end

  describe '#find_pipeline' do
    let(:pipeline) { create(:ci_pipeline) }

    shared_examples 'pipeline finder' do
      context 'when pipeline exists' do
        it 'returns requested pipeline' do
          expect(helper.find_pipeline(existing_id)).to eq(pipeline)
        end
      end

      context 'when pipeline does not exists' do
        it 'returns nil' do
          expect(helper.find_pipeline(non_existing_id)).to be_nil
        end
      end

      context 'when pipeline id is not provided' do
        it 'returns nil' do
          expect(helper.find_pipeline(nil)).to be_nil
        end
      end
    end

    context 'when ID is used as an argument' do
      let(:existing_id) { pipeline.id }
      let(:non_existing_id) { non_existing_record_id }

      it_behaves_like 'pipeline finder'
    end

    context 'when string ID is used as an argument' do
      let(:existing_id) { pipeline.id.to_s }
      let(:non_existing_id) { non_existing_record_id }

      it_behaves_like 'pipeline finder'
    end

    context 'when ID is a negative number' do
      let(:existing_id) { pipeline.id }
      let(:non_existing_id) { -1 }

      it_behaves_like 'pipeline finder'
    end
  end

  describe '#find_pipeline!' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:user) { create(:user) }

    shared_examples 'private project without access' do
      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      it 'returns not found' do
        expect(helper).to receive(:not_found!)

        helper.find_pipeline!(pipeline.id)
      end
    end

    context 'when user is authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:initial_current_user).and_return(user)
      end

      context 'public project' do
        it 'returns requested pipeline' do
          expect(helper.find_pipeline!(pipeline.id)).to eq(pipeline)
        end
      end

      context 'private project' do
        it_behaves_like 'private project without access'

        context 'without read pipeline permission' do
          before do
            allow(helper).to receive(:can?).with(user, :read_pipeline, pipeline).and_return(false)
          end

          it_behaves_like 'private project without access'
        end
      end

      context 'with read pipeline permission' do
        before do
          allow(helper).to receive(:can?).with(user, :read_pipeline, pipeline).and_return(true)
        end

        it 'returns requested pipeline' do
          expect(helper.find_pipeline!(pipeline.id)).to eq(pipeline)
        end
      end
    end

    context 'when user is not authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
        allow(helper).to receive(:initial_current_user).and_return(nil)
      end

      context 'public project' do
        it 'returns requested pipeline' do
          expect(helper.find_pipeline!(pipeline.id)).to eq(pipeline)
        end
      end

      context 'private project' do
        it_behaves_like 'private project without access'
      end
    end

    context 'support for IDs and paths as argument' do
      let_it_be(:project) { create(:project) }
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

      let(:user) { project.first_owner }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:authorized_project_scope?).and_return(true)
        allow(helper).to receive(:job_token_authentication?).and_return(false)
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      shared_examples 'pipeline finder' do
        context 'when pipeline exists' do
          it 'returns requested pipeline' do
            expect(helper.find_pipeline!(existing_id)).to eq(pipeline)
          end

          it 'returns nil' do
            expect(helper).to receive(:render_api_error!).with('404 Pipeline Not Found', 404)
            expect(helper.find_pipeline!(non_existing_id)).to be_nil
          end
        end
      end

      context 'when ID is used as an argument' do
        context 'when pipeline id is an integer' do
          let(:existing_id) { pipeline.id }
          let(:non_existing_id) { non_existing_record_id }

          it_behaves_like 'pipeline finder'
        end

        context 'when pipeline id is a string' do
          let(:existing_id) { pipeline.id.to_s }
          let(:non_existing_id) { "non_existing_record_id" }

          it_behaves_like 'pipeline finder'
        end
      end
    end
  end

  describe '#find_organization!' do
    let_it_be(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:initial_current_user).and_return(user)
    end

    context 'when organization is public' do
      let_it_be(:public_organization) { create(:organization, :public) }

      context 'when user is authenticated' do
        it 'returns requested organization' do
          expect(helper.find_organization!(public_organization.id)).to eq(public_organization)
        end
      end

      context 'when user is not authenticated' do
        let(:user) { nil }

        it 'returns requested organization' do
          expect(helper.find_organization!(public_organization.id)).to eq(public_organization)
        end
      end
    end

    context 'when organization is private' do
      let_it_be(:private_organization) { create(:organization, :private) }

      context 'when user is authenticated' do
        context 'when user is part of the organization' do
          before_all do
            create(:organization_user, user: user, organization: private_organization)
          end

          it 'returns requested organization' do
            expect(helper.find_organization!(private_organization.id)).to eq(private_organization)
          end
        end

        context 'when user is not part of the organization' do
          it 'returns nil' do
            expect(helper).to receive(:render_api_error!).with('404 Organization Not Found', 404)
            expect(helper.find_organization!(private_organization)).to be_nil
          end
        end
      end

      context 'when user is not authenticated' do
        let(:user) { nil }

        it 'returns nil' do
          expect(helper).to receive(:render_api_error!).with('404 Organization Not Found', 404)
          expect(helper.find_organization!(private_organization)).to be_nil
        end
      end
    end

    context 'when organization does not exist' do
      it 'returns nil' do
        expect(helper).to receive(:render_api_error!).with('404 Organization Not Found', 404)
        expect(helper.find_organization!(non_existing_record_id)).to be_nil
      end
    end
  end

  describe '#find_group!' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    shared_examples 'private group without access' do
      before do
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      it 'returns not found' do
        expect(helper).to receive(:not_found!)

        helper.find_group!(group.id)
      end
    end

    context 'when user is authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:initial_current_user).and_return(user)
      end

      context 'public group' do
        it 'returns requested group' do
          expect(helper.find_group!(group.id)).to eq(group)
        end
      end

      context 'private group' do
        it_behaves_like 'private group without access'
      end
    end

    context 'when user is not authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
        allow(helper).to receive(:initial_current_user).and_return(nil)
      end

      context 'public group' do
        it 'returns requested group' do
          expect(helper.find_group!(group.id)).to eq(group)
        end
      end

      context 'private group' do
        it_behaves_like 'private group without access'
      end
    end

    context 'with support for IDs and paths as arguments' do
      let_it_be(:group) { create(:group) }

      let(:user) { group.first_owner }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:authorized_project_scope?).and_return(true)
        allow(helper).to receive(:job_token_authentication?).and_return(false)
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      shared_examples 'group finder' do
        context 'when group exists' do
          it 'returns requested group' do
            expect(helper.find_group!(existing_id)).to eq(group)
          end

          it 'returns nil' do
            expect(helper).to receive(:render_api_error!).with('404 Group Not Found', 404)
            expect(helper.find_group!(non_existing_id)).to be_nil
          end
        end
      end

      context 'when ID is used as an argument' do
        let(:existing_id) { group.id }
        let(:non_existing_id) { non_existing_record_id }

        it_behaves_like 'group finder'
      end

      context 'when PATH is used as an argument' do
        let(:existing_id) { group.full_path }
        let(:non_existing_id) { 'something/else' }

        it_behaves_like 'group finder'
      end

      context 'when ID is a negative number' do
        let(:existing_id) { group.id }
        let(:non_existing_id) { -1 }

        it_behaves_like 'group finder'
      end
    end
  end

  context 'with support for organization as an argument' do
    let_it_be(:group) { create(:group) }
    let_it_be(:organization) { create(:organization) }

    before do
      allow(helper).to receive(:current_user).and_return(group.first_owner)
      allow(helper).to receive(:job_token_authentication?).and_return(false)
      allow(helper).to receive(:authenticate_non_public?).and_return(false)
    end

    subject { helper.find_group!(group.id, organization: organization) }

    context 'when group exists in the organization' do
      before do
        group.update!(organization: organization)
      end

      it { is_expected.to eq(group) }
    end

    context 'when group does not exist in the organization' do
      it 'returns nil' do
        expect(helper).to receive(:render_api_error!).with('404 Group Not Found', 404)
        is_expected.to be_nil
      end
    end
  end

  describe '#find_group_by_full_path!' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    shared_examples 'private group without access' do
      before do
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      it 'returns not found' do
        expect(helper).to receive(:not_found!)

        helper.find_group_by_full_path!(group.full_path)
      end
    end

    context 'when user is authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:initial_current_user).and_return(user)
      end

      context 'public group' do
        it 'returns requested group' do
          expect(helper.find_group_by_full_path!(group.full_path)).to eq(group)
        end
      end

      context 'private group' do
        it_behaves_like 'private group without access'

        context 'with access' do
          before do
            group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
            group.add_developer(user)
          end

          it 'returns requested group with access' do
            expect(helper.find_group_by_full_path!(group.full_path)).to eq(group)
          end
        end
      end
    end

    context 'when user is not authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
        allow(helper).to receive(:initial_current_user).and_return(nil)
      end

      context 'public group' do
        it 'returns requested group' do
          expect(helper.find_group_by_full_path!(group.full_path)).to eq(group)
        end
      end

      context 'private group' do
        it_behaves_like 'private group without access'
      end
    end
  end

  describe '#find_namespace' do
    let(:namespace) { create(:namespace) }

    shared_examples 'namespace finder' do
      context 'when namespace exists' do
        it 'returns requested namespace' do
          expect(helper.find_namespace(existing_id)).to eq(namespace)
        end
      end

      context "when namespace doesn't exists" do
        it 'returns nil' do
          expect(helper.find_namespace(non_existing_id)).to be_nil
        end
      end
    end

    context 'when ID is used as an argument' do
      let(:existing_id) { namespace.id }
      let(:non_existing_id) { non_existing_record_id }

      it_behaves_like 'namespace finder'

      it 'find the namespace from up-to-date replica or primary DB' do
        allow(Namespace.sticking).to receive(:find_caught_up_replica).and_call_original

        expect(Namespace.sticking).to receive(:find_caught_up_replica).with(:namespace, existing_id)
        expect(helper.find_namespace(existing_id)).to eq(namespace)
      end
    end

    context 'when PATH is used as an argument' do
      let(:existing_id) { namespace.path }
      let(:non_existing_id) { 'non-existing-path' }

      it_behaves_like 'namespace finder'
    end

    context 'when ID is a negative number' do
      let(:existing_id) { namespace.id }
      let(:non_existing_id) { -1 }

      it_behaves_like 'namespace finder'
    end
  end

  shared_examples 'user namespace finder' do
    let(:user1) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user1)
      allow(helper).to receive(:header).and_return(nil)
      allow(helper).to receive(:not_found!).and_raise('404 Namespace not found')
    end

    context 'when namespace is group' do
      let(:namespace) { create(:group) }

      context 'when user has access to group' do
        before do
          namespace.add_guest(user1)
          namespace.save!
        end

        it 'returns requested namespace' do
          expect(namespace_finder).to eq(namespace)
        end
      end

      context "when user doesn't have access to group" do
        it 'raises not found error' do
          expect { namespace_finder }.to raise_error(RuntimeError, '404 Namespace not found')
        end
      end
    end

    context "when namespace is user's personal namespace" do
      let(:namespace) { create(:namespace) }

      context 'when user owns the namespace' do
        before do
          namespace.owner = user1
          namespace.save!
        end

        it 'returns requested namespace' do
          expect(namespace_finder).to eq(namespace)
        end
      end

      context "when user doesn't own the namespace" do
        it 'raises not found error' do
          expect { namespace_finder }.to raise_error(RuntimeError, '404 Namespace not found')
        end
      end
    end
  end

  describe '#find_namespace!' do
    let(:namespace_finder) do
      helper.find_namespace!(namespace.id)
    end

    it_behaves_like 'user namespace finder'
  end

  describe '#authorized_project_scope?' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:job) { create(:ci_build) }

    let(:send_authorized_project_scope) { helper.authorized_project_scope?(project) }

    where(:job_token_authentication, :route_setting, :same_job_project, :expected_result) do
      false | false | false | true
      false | false | true  | true
      false | true  | false | true
      false | true  | true  | true
      true  | false | false | true
      true  | false | true  | true
      true  | true  | false | false
      true  | true  | true  | true
    end

    with_them do
      before do
        allow(helper).to receive(:job_token_authentication?).and_return(job_token_authentication)
        allow(helper).to receive(:route_authentication_setting).and_return(job_token_scope: route_setting ? :project : nil)
        allow(helper).to receive(:current_authenticated_job).and_return(job)
        allow(job).to receive(:project).and_return(same_job_project ? project : other_project)
      end

      it 'returns the expected result' do
        expect(send_authorized_project_scope).to eq(expected_result)
      end
    end
  end

  describe '#send_git_blob' do
    let(:repository) { double }
    let(:blob) { double(name: 'foobar') }

    let(:send_git_blob) do
      helper.send(:send_git_blob, repository, blob)
      helper.header
    end

    before do
      allow(helper).to receive(:env).and_return({})
      allow(helper).to receive(:content_type)
      allow(helper).to receive(:header).and_return({})
      allow(helper).to receive(:body).and_return('')
      allow(Gitlab::Workhorse).to receive(:send_git_blob)
    end

    it 'sets Gitlab::Workhorse::DETECT_HEADER header' do
      expect(send_git_blob[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
    end

    context 'content disposition' do
      context 'when blob name is null' do
        let(:blob) { double(name: nil) }

        it 'returns only the disposition' do
          expect(send_git_blob['Content-Disposition']).to eq 'inline'
        end
      end

      context 'when blob name is not null' do
        it 'returns disposition with the blob name' do
          expect(send_git_blob['Content-Disposition']).to eq %q(inline; filename="foobar"; filename*=UTF-8''foobar)
        end

        context 'when blob name ends with an xhtml extension' do
          let(:blob) { instance_double(Gitlab::Git::Blob, name: 'foo.bar.xhtml') }

          it 'returns the name without extension' do
            expect(send_git_blob['Content-Disposition']).to eq %q(inline; filename="foo"; filename*=UTF-8''foo)
          end
        end
      end
    end
  end

  describe '#increment_unique_values' do
    let(:value) { '9f302fea-f828-4ca9-aef4-e10bd723c0b3' }
    let(:event_name) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    it 'tracks redis hll event' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(event_name, values: value)

      helper.increment_unique_values(event_name, value)
    end

    it 'logs an exception for unknown event' do
      expect(Gitlab::AppLogger).to receive(:warn).with("Redis tracking event failed for event: #{unknown_event}, message: Unknown event #{unknown_event}")

      helper.increment_unique_values(unknown_event, value)
    end

    it 'does not track event for nil values' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      helper.increment_unique_values(unknown_event, nil)
    end
  end

  describe '#track_event' do
    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project) }
    let(:event_name) { 'i_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    it 'tracks internal event' do
      expect(Gitlab::InternalEvents).to receive(:track_event).with(
        event_name,
        send_snowplow_event: true,
        additional_properties: {},
        user: user,
        namespace: namespace,
        project: project
      )

      helper.track_event(event_name,
        user: user,
        namespace_id: namespace.id,
        project_id: project.id
      )
    end

    it 'passes send_snowplow_event on to InternalEvents.track_event' do
      expect(Gitlab::InternalEvents).to receive(:track_event).with(
        event_name,
        send_snowplow_event: false,
        additional_properties: {},
        user: user,
        namespace: namespace,
        project: project
      )

      helper.track_event(event_name,
        send_snowplow_event: false,
        user: user,
        namespace_id: namespace.id,
        project_id: project.id
      )
    end

    it 'passes additional_properties on to InternalEvents.track_event' do
      expect(Gitlab::InternalEvents).to receive(:track_event).with(
        event_name,
        send_snowplow_event: true,
        additional_properties: { label: 'label2' },
        user: user,
        namespace: namespace,
        project: project
      )

      helper.track_event(event_name,
        user: user,
        namespace_id: namespace.id,
        project_id: project.id,
        additional_properties: { label: 'label2' }
      )
    end

    it 'tracks an exception and renders 422 for unknown event', :aggregate_failures do
      # expect(Gitlab::InternalEvents).to receive(:track_event).and_raise(Gitlab::InternalEvents::UnknownEventError, "Unknown event: #{unknown_event}")

      expect(Gitlab::ErrorTracking).to receive(:track_exception)
        .with(
          instance_of(Gitlab::Tracking::EventValidator::UnknownEventError),
          event_name: unknown_event
        )
      expect(helper).to receive(:unprocessable_entity!).with("Unknown event: #{unknown_event}")

      helper.track_event(unknown_event,
        user: user,
        namespace_id: namespace.id,
        project_id: project.id
      )
    end

    it 'logs an exception for tracking errors' do
      expect(Gitlab::InternalEvents).to receive(:track_event).and_raise(ArgumentError, "Error message")
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        .with(
          instance_of(ArgumentError),
          event_name: unknown_event
        )

      helper.track_event(unknown_event,
        user: user,
        namespace_id: namespace.id,
        project_id: project.id
      )
    end

    it 'does not track event for nil user' do
      expect(Gitlab::InternalEvents).not_to receive(:track_event)

      helper.track_event(unknown_event,
        user: nil,
        namespace_id: namespace.id,
        project_id: project.id
      )
    end
  end

  shared_examples '#order_options_with_tie_breaker' do
    subject { Class.new.include(described_class).new.order_options_with_tie_breaker(**reorder_params) }

    let(:reorder_params) { {} }

    before do
      allow_any_instance_of(described_class).to receive(:params).and_return(params)
    end

    context 'with non-id order given' do
      context 'with ascending order' do
        let(:params) { { order_by: 'name', sort: 'asc' } }

        it 'adds id based ordering with same direction as primary order' do
          is_expected.to eq({ 'name' => 'asc', 'id' => 'asc' })
        end
      end

      context 'with descending order' do
        let(:params) { { order_by: 'name', sort: 'desc' } }

        it 'adds id based ordering with same direction as primary order' do
          is_expected.to eq({ 'name' => 'desc', 'id' => 'desc' })
        end
      end
    end

    context 'with non-id order but no direction given' do
      let(:params) { { order_by: 'name' } }

      it 'adds ID ASC order' do
        is_expected.to eq({ 'name' => nil, 'id' => 'asc' })
      end
    end

    context 'with id order given' do
      let(:params) { { order_by: 'id', sort: 'asc' } }

      it 'does not add an additional order' do
        is_expected.to eq({ 'id' => 'asc' })
      end
    end
  end

  describe '#order_options_with_tie_breaker' do
    include_examples '#order_options_with_tie_breaker'

    context 'by default' do
      context 'with created_at order given' do
        let(:params) { { order_by: 'created_at', sort: 'asc' } }

        it 'converts to id' do
          is_expected.to eq({ 'id' => 'asc' })
        end
      end
    end

    context 'when override_created_at is false' do
      let(:reorder_params) { { override_created_at: false } }

      context 'with created_at order given' do
        let(:params) { { order_by: 'created_at', sort: 'asc' } }

        it 'does not convert to id' do
          is_expected.to eq({ "created_at" => "asc", "id" => "asc" })
        end
      end
    end
  end

  describe "#destroy_conditionally!" do
    let!(:project) { create(:project) }

    context 'when unmodified check passes' do
      before do
        allow(helper).to receive(:check_unmodified_since!).with(project.updated_at).and_return(true)
      end

      it 'destroys given project' do
        allow(helper).to receive(:status).with(204)
        allow(helper).to receive(:body).with(false)
        expect(project).to receive(:destroy).and_call_original

        expect { helper.destroy_conditionally!(project) }.to change(Project, :count).by(-1)
      end
    end

    context 'when unmodified check fails' do
      before do
        allow(helper).to receive(:check_unmodified_since!).with(project.updated_at).and_throw(:error)
      end

      # #destroy_conditionally! uses Grape errors which Ruby-throws a symbol, shifting execution to somewhere else.
      # Since this spec isn't in the Grape context, we need to simulate this ourselves.
      # Grape throws here: https://github.com/ruby-grape/grape/blob/470f80cd48933cdf11d4c1ee02cb43e0f51a7300/lib/grape/dsl/inside_route.rb#L168-L171
      # And catches here: https://github.com/ruby-grape/grape/blob/cf57d250c3d77a9a488d9f56918d62fd4ac745ff/lib/grape/middleware/error.rb#L38-L40
      it 'does not destroy given project' do
        expect(project).not_to receive(:destroy)

        expect { helper.destroy_conditionally!(project) }.to throw_symbol(:error).and change { Project.count }.by(0)
      end
    end
  end

  describe "#check_unmodified_since!" do
    let(:unmodified_since_header) { Time.now.change(usec: 0) }

    before do
      allow(helper).to receive(:headers).and_return('If-Unmodified-Since' => unmodified_since_header.to_s)
    end

    context 'when last modified is later than header value' do
      it 'renders error' do
        expect(helper).to receive(:render_api_error!)

        helper.check_unmodified_since!(unmodified_since_header + 1.hour)
      end
    end

    context 'when last modified is earlier than header value' do
      it 'does not render error' do
        expect(helper).not_to receive(:render_api_error!)

        helper.check_unmodified_since!(unmodified_since_header - 1.hour)
      end
    end

    context 'when last modified is equal to header value' do
      it 'does not render error' do
        expect(helper).not_to receive(:render_api_error!)

        helper.check_unmodified_since!(unmodified_since_header)
      end
    end

    context 'when there is no header value present' do
      let(:unmodified_since_header) { nil }

      it 'does not render error' do
        expect(helper).not_to receive(:render_api_error!)

        helper.check_unmodified_since!(Time.now)
      end
    end

    context 'when header value is not a valid time value' do
      let(:unmodified_since_header) { "abcd" }

      it 'does not render error' do
        expect(helper).not_to receive(:render_api_error!)

        helper.check_unmodified_since!(Time.now)
      end
    end
  end

  describe '#present_disk_file!' do
    let_it_be(:dummy_class) do
      Class.new do
        attr_reader :headers
        alias_method :header, :headers

        def initialize
          @headers = {}
        end
      end
    end

    let(:dummy_instance) { dummy_class.include(described_class).new }
    let(:path) { '/tmp/file.txt' }
    let(:filename) { 'file.txt' }
    let(:extra_response_headers) { {} }

    subject { dummy_instance.present_disk_file!(path, filename, extra_response_headers: extra_response_headers) }

    before do
      expect(dummy_instance).to receive(:content_type).with('application/octet-stream')
    end

    context 'with X-Sendfile supported' do
      before do
        dummy_instance.headers['X-Sendfile-Type'] = 'X-Sendfile'
      end

      it 'sends the file using X-Sendfile' do
        expect(dummy_instance).to receive(:body).with('')

        subject

        expect(dummy_instance.headers['X-Sendfile']).to eq(path)
      end
    end

    context 'without X-Sendfile supported' do
      it 'sends the file' do
        expect(dummy_instance).to receive(:sendfile).with(path)

        subject
      end
    end

    context 'with extra response headers' do
      let(:extra_response_headers) { { 'x-custom-header' => 'test' } }

      it 'sets them' do
        expect(dummy_instance).to receive(:sendfile).with(path)

        subject

        expect(dummy_instance.headers['x-custom-header']).to eq('test')
      end
    end
  end

  describe '#present_carrierwave_file!' do
    let(:supports_direct_download) { false }
    let(:content_type) { nil }
    let(:content_disposition) { nil }
    let(:extra_response_headers) { {} }

    subject do
      helper.present_carrierwave_file!(
        artifact.file,
        supports_direct_download: supports_direct_download,
        content_disposition: content_disposition,
        content_type: content_type,
        extra_response_headers: extra_response_headers
      )
    end

    context 'with file storage' do
      let_it_be(:artifact) { create(:ci_job_artifact, :zip) }

      it 'calls present_disk_file!' do
        expect(helper).to receive(:present_disk_file!).with(artifact.file.path, artifact.filename, content_type: nil, extra_response_headers: extra_response_headers)

        subject
      end

      context 'with an overriden content type' do
        let(:content_type) { 'application/zip' }

        it 'calls present_disk_file! with the correct content type' do
          expect(helper).to receive(:present_disk_file!).with(artifact.file.path, artifact.filename, content_type: content_type, extra_response_headers: extra_response_headers)

          subject
        end
      end

      context 'with extra response headers' do
        let(:extra_response_headers) { { 'x-custom-header' => 'test' } }

        it 'calls present_disk_file! with the correct extra response headers' do
          expect(helper).to receive(:present_disk_file!)
            .with(artifact.file.path, artifact.filename, content_type: content_type, extra_response_headers: extra_response_headers)

          subject
        end
      end
    end

    context 'with remote storage' do
      let(:artifact) { create(:ci_job_artifact, :zip, :remote_store) }

      before do
        allow(helper).to receive(:env).and_return({})
        allow(helper).to receive(:request).and_return(instance_double(Rack::Request, head?: false))
        stub_artifacts_object_storage(enabled: true)
      end

      context 'with direct upload available' do
        let(:supports_direct_download) { true }

        it 'sends a redirect' do
          expect(helper).to receive(:redirect).with(an_instance_of(String))

          subject
        end

        context 'with an overriden content type' do
          let(:content_type) { 'application/zip' }
          let(:content_disposition) { :inline }

          it 'sends a redirect with the correct content type' do
            expect(helper).to receive(:redirect) do |url|
              expect(url).to include("response-content-type=#{CGI.escape(content_type)}")
            end

            subject
          end
        end
      end

      context 'with direct upload not available' do
        let(:supports_direct_download) { false }

        it 'sends a workhorse header' do
          expect(helper).to receive(:header).with(Gitlab::Workhorse::SEND_DATA_HEADER, an_instance_of(String))
          expect(helper).to receive(:status).with(:ok)
          expect(helper).to receive(:body).with('')

          subject
        end

        context 'with an overriden content type' do
          let(:content_type) { 'application/zip' }
          let(:content_disposition) { :inline }

          it 'sends a workhorse header with the correct content type' do
            expect(helper).to receive(:status).with(:ok)
            expect(helper).to receive(:body).with('')
            expect(helper).to receive(:header) do |name, value|
              expect(name).to eq(Gitlab::Workhorse::SEND_DATA_HEADER)
              command, encoded_params = value.split(":")
              params = Gitlab::Json.parse(Base64.urlsafe_decode64(encoded_params))

              expect(command).to eq('send-url')
              expect(params.dig('ResponseHeaders', 'Content-Type')).to eq([content_type])
            end

            subject
          end
        end

        context 'with extra response headers' do
          let(:extra_response_headers) { { 'x-custom-header' => 'test' } }

          it 'sends a workhorse header with the response headers' do
            expect(helper).to receive(:status).with(:ok)
            expect(helper).to receive(:body).with('')
            expect(helper).to receive(:header) do |name, value|
              expect(name).to eq(Gitlab::Workhorse::SEND_DATA_HEADER)
              command, encoded_params = value.split(":")
              params = Gitlab::Json.parse(Base64.urlsafe_decode64(encoded_params))

              expect(command).to eq('send-url')
              expect(params.dig('ResponseHeaders', 'x-custom-header')).to eq(['test'])
            end

            subject
          end
        end
      end
    end
  end

  describe '#present_artifacts_file!' do
    context 'with object storage' do
      let(:artifact) { create(:ci_job_artifact, :zip, :remote_store) }
      let(:is_head_request) { false }

      subject { helper.present_artifacts_file!(artifact.file) }

      before do
        allow(helper).to receive(:env).and_return({})
        allow(helper).to receive(:request).and_return(instance_double(Rack::Request, head?: is_head_request))
        stub_artifacts_object_storage(enabled: true)
      end

      it 'redirects to a CDN-fronted URL' do
        expect(helper).to receive(:redirect)
        expect_next_instance_of(ObjectStorage::CDN::FileUrl) do |instance|
          expect(instance).to receive(:url).and_call_original
        end
        expect(Gitlab::ApplicationContext).to receive(:push).with(artifact: artifact.file.model).and_call_original
        expect(Gitlab::ApplicationContext).to receive(:push).with(artifact_used_cdn: false).and_call_original

        subject
      end

      context 'requested with HEAD' do
        let(:is_head_request) { true }

        it 'redirects to a CDN-fronted URL' do
          expect(helper).to receive(:redirect)
          expect(ObjectStorage::S3).to receive(:signed_head_url).and_call_original
          expect(Gitlab::ApplicationContext).to receive(:push).with(artifact: artifact.file.model).and_call_original

          subject
        end
      end

      context 'with content_disposition' do
        let(:filename) { artifact.file.filename }
        let(:redirect_params) do
          {
            query: {
              'response-content-disposition' => "attachment; filename=\"#{filename}\"; filename*=UTF-8''#{filename}",
              'response-content-type' => 'application/zip'
            }
          }
        end

        subject { helper.present_artifacts_file!(artifact.file, content_disposition: :attachment) }

        it 'redirects as an attachment' do
          expect(helper).to receive(:redirect)
          expect(ObjectStorage::CDN::FileUrl).to receive(:new)
            .with(file: anything, ip_address: anything, redirect_params: redirect_params).and_call_original

          subject
        end
      end
    end
  end

  describe '#order_by_similarity?' do
    where(:params, :allow_unauthorized, :current_user_set, :expected) do
      {}                                          | false | false | false
      {}                                          | true  | false | false
      {}                                          | false | true  | false
      {}                                          | true  | true  | false
      { order_by: 'similarity' }                  | false | false | false
      { order_by: 'similarity' }                  | true  | false | false
      { order_by: 'similarity' }                  | true  | true  | false
      { order_by: 'similarity' }                  | false | true  | false
      { search: 'test' }                          | false | false | false
      { search: 'test' }                          | true  | false | false
      { search: 'test' }                          | true  | true  | false
      { search: 'test' }                          | false | true  | false
      { order_by: 'similarity', search: 'test' }  | false | false | false
      { order_by: 'similarity', search: 'test' }  | true  | false | true
      { order_by: 'similarity', search: 'test' }  | true  | true  | true
      { order_by: 'similarity', search: 'test' }  | false | true  | true
    end

    with_them do
      let_it_be(:user) { create(:user) }

      before do
        u = current_user_set ? user : nil
        helper.instance_variable_set(:@current_user, u)

        allow(helper).to receive(:params).and_return(params)
      end

      it 'returns the expected result' do
        expect(helper.order_by_similarity?(allow_unauthorized: allow_unauthorized)).to eq(expected)
      end
    end
  end

  describe '#render_api_error_with_reason!' do
    before do
      allow(helper).to receive(:env).and_return({})
      allow(helper).to receive(:header).and_return({})
      allow(helper).to receive(:error!)
    end

    it 'renders error with code' do
      expect(helper).to receive(:set_status_code_in_env).with(999)
      expect(helper).to receive(:error!).with({ 'message' => 'a message - good reason' }, 999, {})

      helper.render_api_error_with_reason!(999, 'a message', 'good reason')
    end
  end

  describe '#unauthorized!' do
    it 'renders 401' do
      expect(helper).to receive(:render_api_error_with_reason!).with(401, '401 Unauthorized', nil)

      helper.unauthorized!
    end

    it 'renders 401 with a reason' do
      expect(helper).to receive(:render_api_error_with_reason!).with(401, '401 Unauthorized', 'custom reason')

      helper.unauthorized!('custom reason')
    end
  end

  describe '#forbidden!' do
    it 'renders 401' do
      expect(helper).to receive(:render_api_error_with_reason!).with(403, '403 Forbidden', nil)

      helper.forbidden!
    end

    it 'renders 401 with a reason' do
      expect(helper).to receive(:render_api_error_with_reason!).with(403, '403 Forbidden', 'custom reason')

      helper.forbidden!('custom reason')
    end
  end

  describe '#bad_request!' do
    it 'renders 400' do
      expect(helper).to receive(:render_api_error_with_reason!).with(400, '400 Bad request', nil)

      helper.bad_request!
    end

    it 'renders 401 with a reason' do
      expect(helper).to receive(:render_api_error_with_reason!).with(400, '400 Bad request', 'custom reason')

      helper.bad_request!('custom reason')
    end
  end

  describe '#too_many_requests!', :aggregate_failures do
    let(:headers) { instance_double(Hash) }

    before do
      allow(helper).to receive(:header).and_return(headers)
    end

    it 'renders 429' do
      expect(helper).to receive(:render_api_error!).with('429 Too Many Requests', 429)
      expect(headers).to receive(:[]=).with('Retry-After', 60)

      helper.too_many_requests!
    end

    it 'renders 429 with a custom message' do
      expect(helper).to receive(:render_api_error!).with('custom message', 429)
      expect(headers).to receive(:[]=).with('Retry-After', 60)

      helper.too_many_requests!('custom message')
    end

    it 'renders 429 with a custom Retry-After value' do
      expect(helper).to receive(:render_api_error!).with('429 Too Many Requests', 429)
      expect(headers).to receive(:[]=).with('Retry-After', 120)

      helper.too_many_requests!(retry_after: 2.minutes)
    end

    it 'renders 429 without a Retry-After value' do
      expect(helper).to receive(:render_api_error!).with('429 Too Many Requests', 429)
      expect(headers).not_to receive(:[]=)

      helper.too_many_requests!(retry_after: nil)
    end
  end

  describe '#authenticate_by_gitlab_shell_token!' do
    include GitlabShellHelpers

    let(:valid_secret_token) { 'valid' }
    let(:invalid_secret_token) { 'invalid' }
    let(:headers) { {} }
    let(:params) { {} }

    shared_examples 'authorized' do
      it 'authorized' do
        expect(helper).not_to receive(:unauthorized!)

        helper.authenticate_by_gitlab_shell_token!
      end
    end

    shared_examples 'unauthorized' do
      it 'unauthorized' do
        expect(helper).to receive(:unauthorized!)

        helper.authenticate_by_gitlab_shell_token!
      end
    end

    before do
      allow(Gitlab::Shell).to receive(:secret_token).and_return(valid_secret_token)
      allow(helper).to receive_messages(params: params, headers: headers, secret_token: valid_secret_token)
    end

    context 'when jwt token is not provided' do
      it_behaves_like 'unauthorized'
    end

    context 'when jwt token is invalid' do
      let(:headers) { gitlab_shell_internal_api_request_header(secret_token: invalid_secret_token) }

      it_behaves_like 'unauthorized'
    end

    context 'when jwt token issuer is invalid' do
      let(:headers) { gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse') }

      it_behaves_like 'unauthorized'
    end

    context 'when jwt token is valid' do
      let(:headers) { gitlab_shell_internal_api_request_header }

      it_behaves_like 'authorized'
    end
  end

  describe "attributes_for_keys" do
    let(:hash) do
      {
        existing_key_with_present_value: 'actual value',
        existing_key_with_nil_value: nil,
        existing_key_with_false_value: false
      }
    end

    let(:parameters) { ::ActionController::Parameters.new(hash) }
    let(:symbol_keys) do
      %i[
        existing_key_with_present_value
        existing_key_with_nil_value
        existing_key_with_false_value
        non_existing_key
      ]
    end

    let(:string_keys) { symbol_keys.map(&:to_s) }
    let(:filtered_attrs) do
      {
        'existing_key_with_present_value' => 'actual value',
        'existing_key_with_false_value' => false
      }
    end

    let(:empty_attrs) { {} }

    where(:params, :keys, :attrs_result) do
      ref(:hash) | ref(:symbol_keys) | ref(:filtered_attrs)
      ref(:hash) | ref(:string_keys) | ref(:empty_attrs)
      ref(:parameters) | ref(:symbol_keys) | ref(:filtered_attrs)
      ref(:parameters) | ref(:string_keys) | ref(:filtered_attrs)
    end

    with_them do
      it 'returns the values for given keys' do
        expect(helper.attributes_for_keys(keys, params)).to eq(attrs_result)
      end
    end
  end

  describe '#authenticate_by_gitlab_shell_or_workhorse_token!' do
    include GitlabShellHelpers
    include WorkhorseHelpers

    include_context 'workhorse headers'

    let(:headers) { {} }
    let(:params) { {} }

    context 'when request from gitlab shell' do
      let(:valid_secret_token) { 'valid' }
      let(:invalid_secret_token) { 'invalid' }

      before do
        allow(helper).to receive_messages(headers: headers)
      end

      context 'with invalid token' do
        let(:headers) { gitlab_shell_internal_api_request_header(secret_token: invalid_secret_token) }

        it 'unauthorized' do
          expect(helper).to receive(:unauthorized!)

          helper.authenticate_by_gitlab_shell_or_workhorse_token!
        end
      end

      context 'with valid token' do
        let(:headers) { gitlab_shell_internal_api_request_header }

        it 'authorized' do
          expect(helper).not_to receive(:unauthorized!)

          helper.authenticate_by_gitlab_shell_or_workhorse_token!
        end
      end
    end

    context 'when request from gitlab workhorse' do
      let(:env) { {} }
      let(:request) { ActionDispatch::Request.new(env) }

      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:headers).and_return(headers)
        allow(helper).to receive(:request).and_return(request)
        allow(helper).to receive_messages(params: params, headers: headers, env: env)
      end

      context 'with invalid token' do
        let(:headers) { { Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => JWT.encode({ 'iss' => 'gitlab-workhorse' }, 'wrongkey', 'HS256') } }

        before do
          allow(JWT).to receive(:decode).and_return([{ 'iss' => 'gitlab-workhorse' }])
        end

        it 'unauthorized' do
          expect(helper).to receive(:forbidden!)

          helper.authenticate_by_gitlab_shell_or_workhorse_token!
        end
      end

      context 'with valid token' do
        let(:headers) { workhorse_headers }
        let(:env) { { 'HTTP_GITLAB_WORKHORSE' => 1 } }

        it 'authorized' do
          expect(helper).not_to receive(:forbidden!)

          helper.authenticate_by_gitlab_shell_or_workhorse_token!
        end
      end
    end
  end
end

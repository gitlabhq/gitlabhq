# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Policies::ProjectPolicy, feature_category: :package_registry do
  include_context 'ProjectPolicy context'

  let(:project) { public_project }

  subject(:policy) { described_class.new(current_user, project.packages_policy_subject) }

  describe 'deploy token access' do
    let!(:project_deploy_token) do
      create(:project_deploy_token, project: project, deploy_token: deploy_token)
    end

    subject { described_class.new(deploy_token, project.packages_policy_subject) }

    context 'when a deploy token with read_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, read_package_registry: true) }

      it { is_expected.to be_allowed(:read_package) }

      it_behaves_like 'package access with repository disabled'
    end

    context 'when a deploy token with write_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, write_package_registry: true) }

      it { is_expected.to be_allowed(:read_package) }

      it_behaves_like 'package access with repository disabled'
    end
  end

  describe 'read_package', :enable_admin_mode do
    using RSpec::Parameterized::TableSyntax

    where(:project, :package_registry_access_level, :current_user, :expect_to_be_allowed) do
      ref(:private_project)  | ProjectFeature::DISABLED | ref(:anonymous)  | false
      ref(:private_project)  | ProjectFeature::DISABLED | ref(:non_member) | false
      ref(:private_project)  | ProjectFeature::DISABLED | ref(:guest)      | false
      ref(:private_project)  | ProjectFeature::DISABLED | ref(:reporter)   | false
      ref(:private_project)  | ProjectFeature::DISABLED | ref(:developer)  | false
      ref(:private_project)  | ProjectFeature::DISABLED | ref(:maintainer) | false
      ref(:private_project)  | ProjectFeature::DISABLED | ref(:owner)      | false
      ref(:private_project)  | ProjectFeature::DISABLED | ref(:admin)      | false

      ref(:private_project)  | ProjectFeature::PRIVATE  | ref(:anonymous)  | false
      ref(:private_project)  | ProjectFeature::PRIVATE  | ref(:non_member) | false
      ref(:private_project)  | ProjectFeature::PRIVATE  | ref(:guest)      | true
      ref(:private_project)  | ProjectFeature::PRIVATE  | ref(:reporter)   | true
      ref(:private_project)  | ProjectFeature::PRIVATE  | ref(:developer)  | true
      ref(:private_project)  | ProjectFeature::PRIVATE  | ref(:maintainer) | true
      ref(:private_project)  | ProjectFeature::PRIVATE  | ref(:owner)      | true
      ref(:private_project)  | ProjectFeature::PRIVATE  | ref(:admin)      | true

      ref(:private_project)  | ProjectFeature::PUBLIC   | ref(:anonymous)  | true
      ref(:private_project)  | ProjectFeature::PUBLIC   | ref(:non_member) | true
      ref(:private_project)  | ProjectFeature::PUBLIC   | ref(:guest)      | true
      ref(:private_project)  | ProjectFeature::PUBLIC   | ref(:reporter)   | true
      ref(:private_project)  | ProjectFeature::PUBLIC   | ref(:developer)  | true
      ref(:private_project)  | ProjectFeature::PUBLIC   | ref(:maintainer) | true
      ref(:private_project)  | ProjectFeature::PUBLIC   | ref(:owner)      | true
      ref(:private_project)  | ProjectFeature::PUBLIC   | ref(:admin)      | true

      ref(:internal_project) | ProjectFeature::DISABLED | ref(:anonymous)  | false
      ref(:internal_project) | ProjectFeature::DISABLED | ref(:non_member) | false
      ref(:internal_project) | ProjectFeature::DISABLED | ref(:guest)      | false
      ref(:internal_project) | ProjectFeature::DISABLED | ref(:reporter)   | false
      ref(:internal_project) | ProjectFeature::DISABLED | ref(:developer)  | false
      ref(:internal_project) | ProjectFeature::DISABLED | ref(:maintainer) | false
      ref(:internal_project) | ProjectFeature::DISABLED | ref(:owner)      | false
      ref(:internal_project) | ProjectFeature::DISABLED | ref(:admin)      | false

      ref(:internal_project) | ProjectFeature::ENABLED  | ref(:anonymous)  | false
      ref(:internal_project) | ProjectFeature::ENABLED  | ref(:non_member) | true
      ref(:internal_project) | ProjectFeature::ENABLED  | ref(:guest)      | true
      ref(:internal_project) | ProjectFeature::ENABLED  | ref(:reporter)   | true
      ref(:internal_project) | ProjectFeature::ENABLED  | ref(:developer)  | true
      ref(:internal_project) | ProjectFeature::ENABLED  | ref(:maintainer) | true
      ref(:internal_project) | ProjectFeature::ENABLED  | ref(:owner)      | true
      ref(:internal_project) | ProjectFeature::ENABLED  | ref(:admin)      | true

      ref(:internal_project) | ProjectFeature::PUBLIC   | ref(:anonymous)  | true
      ref(:internal_project) | ProjectFeature::PUBLIC   | ref(:non_member) | true
      ref(:internal_project) | ProjectFeature::PUBLIC   | ref(:guest)      | true
      ref(:internal_project) | ProjectFeature::PUBLIC   | ref(:reporter)   | true
      ref(:internal_project) | ProjectFeature::PUBLIC   | ref(:developer)  | true
      ref(:internal_project) | ProjectFeature::PUBLIC   | ref(:maintainer) | true
      ref(:internal_project) | ProjectFeature::PUBLIC   | ref(:owner)      | true
      ref(:internal_project) | ProjectFeature::PUBLIC   | ref(:admin)      | true

      ref(:public_project)   | ProjectFeature::DISABLED | ref(:anonymous)  | false
      ref(:public_project)   | ProjectFeature::DISABLED | ref(:non_member) | false
      ref(:public_project)   | ProjectFeature::DISABLED | ref(:guest)      | false
      ref(:public_project)   | ProjectFeature::DISABLED | ref(:reporter)   | false
      ref(:public_project)   | ProjectFeature::DISABLED | ref(:developer)  | false
      ref(:public_project)   | ProjectFeature::DISABLED | ref(:maintainer) | false
      ref(:public_project)   | ProjectFeature::DISABLED | ref(:owner)      | false
      ref(:public_project)   | ProjectFeature::DISABLED | ref(:admin)      | false

      ref(:public_project)   | ProjectFeature::PUBLIC   | ref(:anonymous)  | true
      ref(:public_project)   | ProjectFeature::PUBLIC   | ref(:non_member) | true
      ref(:public_project)   | ProjectFeature::PUBLIC   | ref(:guest)      | true
      ref(:public_project)   | ProjectFeature::PUBLIC   | ref(:reporter)   | true
      ref(:public_project)   | ProjectFeature::PUBLIC   | ref(:developer)  | true
      ref(:public_project)   | ProjectFeature::PUBLIC   | ref(:maintainer) | true
      ref(:public_project)   | ProjectFeature::PUBLIC   | ref(:owner)      | true
      ref(:public_project)   | ProjectFeature::PUBLIC   | ref(:admin)      | true
    end

    with_them do
      it do
        project.project_feature.update!(package_registry_access_level: package_registry_access_level)

        if expect_to_be_allowed
          is_expected.to be_allowed(:read_package)
        else
          is_expected.to be_disallowed(:read_package)
        end
      end
    end

    context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
      let(:project) { private_project }
      let(:current_user) { guest }

      before do
        stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
      end

      it { is_expected.to be_disallowed(:read_package) }
    end

    context 'with admin' do
      let(:current_user) { admin }

      it_behaves_like 'package access with repository disabled'
    end

    context 'with package_registry_allow_anyone_to_pull_option disabled' do
      where(:project, :expect_to_be_allowed) do
        ref(:private_project)  | false
        ref(:internal_project) | false
        ref(:public_project)   | true
      end

      with_them do
        let(:current_user) { anonymous }

        before do
          stub_application_setting(package_registry_allow_anyone_to_pull_option: false)
          project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
        end

        it do
          if expect_to_be_allowed
            is_expected.to be_allowed(:read_package)
          else
            is_expected.to be_disallowed(:read_package)
          end
        end
      end
    end

    context 'when accessing a project from another project with job token' do
      let_it_be(:other_project) { build_stubbed(:project) }
      let(:current_user) { guest }

      before do
        allow(current_user).to receive(:ci_job_token_scope).and_return(Ci::JobToken::Scope.new(other_project))
        project.project_feature.update!(package_registry_access_level: access_level)
        stub_application_setting(package_registry_allow_anyone_to_pull_option: false)
      end

      where(:project, :access_level, :expect_to_be_allowed) do
        ref(:public_project)   | ProjectFeature::PUBLIC   | true
        ref(:public_project)   | ProjectFeature::ENABLED  | true
        ref(:public_project)   | ProjectFeature::PRIVATE  | false
        ref(:public_project)   | ProjectFeature::DISABLED | false
        ref(:internal_project) | ProjectFeature::PUBLIC   | true
        ref(:internal_project) | ProjectFeature::ENABLED  | true
        ref(:internal_project) | ProjectFeature::PRIVATE  | false
        ref(:internal_project) | ProjectFeature::DISABLED | false
        ref(:private_project)  | ProjectFeature::PUBLIC   | false
        ref(:private_project)  | ProjectFeature::ENABLED  | false
        ref(:private_project)  | ProjectFeature::PRIVATE  | false
        ref(:private_project)  | ProjectFeature::DISABLED | false
      end

      with_them do
        it { expect(policy.allowed?(:read_package)).to eq(expect_to_be_allowed) }
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Generic::FindOrCreatePackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:ci_build) { create(:ci_build, :running, user: user) }

  let(:params) do
    {
      name: 'mypackage',
      version: '0.0.1'
    }
  end

  let(:service) { described_class.new(project, user, params) }

  subject(:response) { service.execute }

  shared_examples 'valid response for new generic package' do
    let(:expected_attributes) { params.merge(last_build_info: nil) }

    it_behaves_like 'returning a success service response'

    it 'creates package' do
      response

      expect(project.packages.generic.last).to have_attributes(
        name: 'mypackage',
        version: '0.0.1',
        last_build_info: nil,
        **expected_attributes
      )
    end
  end

  describe '#execute' do
    context 'when packages does not exist yet' do
      it_behaves_like 'valid response for new generic package'

      it 'create a new package' do
        expect { response }.to change { project.packages.generic.count }.by(1)
      end

      context 'when build is provided' do
        let(:params) { super().merge(build: ci_build) }

        it_behaves_like 'valid response for new generic package' do
          let(:expected_attributes) do
            params.slice(:name, :version)
                  .merge(last_build_info: have_attributes(pipeline: ci_build.pipeline))
          end
        end
      end

      context 'with package protection rule for different roles and package_name_patterns', :enable_admin_mode do
        using RSpec::Parameterized::TableSyntax

        let_it_be(:project_developer) { create(:user, developer_of: project) }
        let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
        let_it_be(:project_owner) { create(:user, owner_of: project) }
        let_it_be(:instance_admin) { create(:admin) }
        let_it_be(:deploy_token) do
          create(:deploy_token, :project, projects: [project], read_package_registry: true,
            write_package_registry: true)
        end

        let_it_be_with_reload(:protection_rule) do
          create(:package_protection_rule,
            project: project,
            package_type: :generic,
            minimum_access_level_for_push: :maintainer)
        end

        let(:package_name) { params[:name] }
        let(:package_name_no_match) { "#{params[:name]}-other" }

        shared_examples 'protected package' do
          it_behaves_like 'returning an error service response', message: 'Package protected.'

          context 'when feateure flag :packages_protected_packages_generic is disabled' do
            before do
              stub_feature_flags(packages_protected_packages_generic: false)
            end

            it_behaves_like 'valid response for new generic package'
          end
        end

        before do
          protection_rule.update!(
            package_name_pattern: package_name_pattern,
            minimum_access_level_for_push: minimum_access_level_for_push
          )
        end

        # rubocop:disable Layout/LineLength -- Avoid formatting in favor of one-line table syntax
        where(:package_name_pattern, :minimum_access_level_for_push, :user, :shared_examples_name) do
          ref(:package_name)          | :maintainer | ref(:deploy_token)       | 'protected package'
          ref(:package_name)          | :maintainer | ref(:project_developer)  | 'protected package'
          ref(:package_name)          | :maintainer | ref(:project_maintainer) | 'valid response for new generic package'
          ref(:package_name)          | :owner      | ref(:deploy_token)       | 'protected package'
          ref(:package_name)          | :owner      | ref(:project_developer)  | 'protected package'
          ref(:package_name)          | :owner      | ref(:project_owner)      | 'valid response for new generic package'
          ref(:package_name)          | :admin      | ref(:deploy_token)       | 'protected package'
          ref(:package_name)          | :admin      | ref(:instance_admin)     | 'valid response for new generic package'
          ref(:package_name)          | :admin      | ref(:project_owner)      | 'protected package'

          ref(:package_name_no_match) | :admin      | ref(:deploy_token)       | 'valid response for new generic package'
          ref(:package_name_no_match) | :admin      | ref(:project_owner)      | 'valid response for new generic package'
          ref(:package_name_no_match) | :maintainer | ref(:deploy_token)       | 'valid response for new generic package'
          ref(:package_name_no_match) | :maintainer | ref(:project_developer)  | 'valid response for new generic package'
          ref(:package_name_no_match) | :maintainer | ref(:project_maintainer) | 'valid response for new generic package'
        end
        # rubocop:enable Layout/LineLength

        with_them do
          it_behaves_like params[:shared_examples_name]
        end
      end
    end

    context 'when packages already exists' do
      let!(:package) { project.packages.generic.create!(params.except(:build)) }

      context 'when package was created manually' do
        context 'when build is provided' do
          let(:params) { super().merge(build: ci_build) }

          it_behaves_like 'valid response for new generic package' do
            let(:expected_attributes) { params.slice(:name, :version) }
          end

          it { expect(response[:package]).to eq package }
        end
      end

      context 'when package was created by pipeline' do
        let(:pipeline) { create(:ci_pipeline, project: project) }

        before do
          package.build_infos.create!(pipeline: pipeline)
        end

        context 'when build is provided' do
          let(:params) { super().merge(build: ci_build) }

          it_behaves_like 'valid response for new generic package' do
            let(:expected_attributes) do
              params.slice(:name, :version)
                    .merge(last_build_info: have_attributes(pipeline: pipeline))
            end
          end

          it { expect(response[:package]).to eq package }

          it 'does not create a new package' do
            expect { response }.not_to change { project.packages.generic.count }
          end
        end
      end

      context 'when a pending_destruction package exists', :aggregate_failures do
        let!(:package) { project.packages.generic.create!(params.merge(status: :pending_destruction)) }

        it_behaves_like 'valid response for new generic package'
      end
    end
  end
end

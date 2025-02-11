# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationPresenter, feature_category: :software_composition_analysis do
  include Gitlab::Routing.url_helpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { build_stubbed(:user) }

  let(:presenter) { described_class.new(project, current_user: current_user) }

  before do
    stub_licensed_features(licensed_scan_types.index_with { true })
    stub_licensed_features(secret_push_protection: true)
  end

  describe '#to_html_data_attribute' do
    subject(:html_data) { presenter.to_html_data_attribute }

    context 'when latest default branch pipeline`s source is not auto devops' do
      let_it_be(:project) { create(:project, :repository) }

      let_it_be(:pipeline) do
        create(
          :ci_pipeline,
          project: project,
          ref: project.default_branch,
          sha: project.commit.sha
        )
      end

      let!(:build_sast) { create(:ci_build, :sast, name: 'semgrep-sast', pipeline: pipeline) }
      let!(:build_dast) { create(:ci_build, :dast, pipeline: pipeline) }
      let!(:build_license_scanning) { create(:ci_build, :license_scanning, pipeline: pipeline) }

      it 'includes links to auto devops and secure product docs' do
        expect(html_data[:auto_devops_help_page_path]).to eq(help_page_path('topics/autodevops/_index.md'))
        expect(html_data[:help_page_path]).to eq(help_page_path('user/application_security/_index.md'))
      end

      it 'returns info that Auto DevOps is not enabled' do
        expect(html_data[:auto_devops_enabled]).to eq(false)
        expect(html_data[:auto_devops_path]).to eq(project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
      end

      it 'includes a link to the latest pipeline' do
        expect(html_data[:latest_pipeline_path]).to eq(project_pipeline_path(project, pipeline))
      end

      context "while retrieving information about user's ability to enable auto_devops" do
        where(:is_admin, :archived, :feature_available, :result) do
          true     | true      | true   | false
          false    | true      | true   | false
          true     | false     | true   | true
          false    | false     | true   | false
          true     | true      | false  | false
          false    | true      | false  | false
          true     | false     | false  | false
          false    | false     | false  | false
        end

        with_them do
          before do
            allow_next_instance_of(described_class) do |presenter|
              allow(presenter).to receive(:can?).and_return(is_admin)
              allow(presenter).to receive(:archived?).and_return(archived)
              allow(presenter).to receive(:feature_available?).and_return(feature_available)
            end
          end

          it 'includes can_enable_auto_devops' do
            expect(html_data[:can_enable_auto_devops]).to eq(result)
          end
        end
      end

      it 'includes feature information' do
        feature = Gitlab::Json.parse(html_data[:features]).find { |scan| scan['type'] == 'sast' }

        expect(feature['type']).to eq('sast')
        expect(feature['configured']).to eq(true)
        expect(feature['configuration_path']).to be_nil
        expect(feature['available']).to eq(true)
        expect(feature['can_enable_by_merge_request']).to eq(true)
        expect(feature['meta_info_path']).to be_nil
        expect(feature['on_demand_available']).to eq(false)
        expect(feature['security_features']).not_to be_empty
      end

      context 'when checking features configured status' do
        let(:features) { Gitlab::Json.parse(html_data[:features]) }

        where(:type, :configured) do
          :dast | true
          :dast_profiles | true
          :sast | true
          :sast_advanced | false
          :sast_iac | false
          :container_scanning | false
          :cluster_image_scanning | false
          :dependency_scanning | false
          :license_scanning | true
          :secret_detection | false
          :coverage_fuzzing | false
          :api_fuzzing | false
          :corpus_management | true
        end

        with_them do
          it 'returns proper configuration status' do
            feature = features.find { |scan| scan['type'] == type.to_s }

            expect(feature['configured']).to eq(configured)
          end
        end
      end

      context 'when the job has more than one report' do
        let(:features) { Gitlab::Json.parse(html_data[:features]) }
        let(:project) { create(:project, :repository) }

        let(:pipeline) do
          create(
            :ci_pipeline,
            project: project,
            ref: project.default_branch,
            sha: project.commit.sha
          )
        end

        let!(:artifacts) do
          { artifacts: { reports: { other_job: ['gl-other-report.json'], sast: ['gl-sast-report.json'] } } }
        end

        let!(:complicated_job) { build_stubbed(:ci_build, name: 'semgrep-sast', options: artifacts) }

        before do
          allow_next_instance_of(::Security::SecurityJobsFinder) do |finder|
            allow(finder).to receive(:execute).and_return([complicated_job])
          end
        end

        where(:type, :configured) do
          :dast | false
          :dast_profiles | true
          :sast | true
          :sast_iac | false
          :container_scanning | false
          :cluster_image_scanning | false
          :dependency_scanning | false
          :license_scanning | true
          :secret_detection | false
          :coverage_fuzzing | false
          :api_fuzzing | false
          :corpus_management | true
        end

        with_them do
          it 'properly detects security jobs' do
            feature = features.find { |scan| scan['type'] == type.to_s }

            expect(feature['configured']).to eq(configured)
          end
        end
      end

      it 'includes a link to the latest pipeline' do
        expect(subject[:latest_pipeline_path]).to eq(project_pipeline_path(project, pipeline))
      end

      context "while retrieving information about gitlab ci file" do
        let(:project) { create(:project, :repository) }

        context 'when a .gitlab-ci.yml file exists' do
          let!(:ci_config) do
            project.repository.create_file(
              project.creator,
              project.ci_config_path_or_default,
              'contents go here',
              message: 'test',
              branch_name: 'master')
          end

          it 'expects gitlab_ci_present to be true' do
            expect(html_data[:gitlab_ci_present]).to eq(true)
          end
        end

        context 'when a .gitlab-ci.yml file does not exist' do
          it 'expects gitlab_ci_present to be false if the file is not present' do
            expect(html_data[:gitlab_ci_present]).to eq(false)
          end
        end
      end

      it 'includes the path to gitlab_ci history' do
        expect(subject[:gitlab_ci_history_path]).to eq(project_blame_path(project, 'master/.gitlab-ci.yml'))
      end
    end

    context 'when the project is empty' do
      let(:project) { create(:project) }

      it 'includes a blank gitlab_ci history path' do
        expect(html_data[:gitlab_ci_history_path]).to eq('')
      end
    end

    context 'when the project has no default branch set' do
      let(:project) { create(:project, :repository) }

      it 'includes the path to gitlab_ci history' do
        allow(project).to receive(:default_branch).and_return(nil)

        expect(html_data[:gitlab_ci_history_path]).to eq(project_blame_path(project, 'master/.gitlab-ci.yml'))
      end
    end

    context "when the latest default branch pipeline's source is auto devops" do
      let_it_be(:project) { create(:project, :repository) }

      let_it_be(:pipeline) do
        create(
          :ci_pipeline,
          :auto_devops_source,
          project: project,
          ref: project.default_branch,
          sha: project.commit.sha
        )
      end

      let!(:build_sast) { create(:ci_build, :sast, name: 'semgrep-sast', pipeline: pipeline, status: 'success') }
      let!(:build_dast) { create(:ci_build, :dast, pipeline: pipeline, status: 'success') }
      let!(:ci_build) { create(:ci_build, :secret_detection, pipeline: pipeline, status: 'pending') }

      it 'reports that auto devops is enabled' do
        expect(html_data[:auto_devops_enabled]).to be_truthy
      end

      context 'when gathering feature data' do
        let(:features) { Gitlab::Json.parse(html_data[:features]) }

        where(:type, :configured) do
          :dast | true
          :dast_profiles | true
          :sast | true
          :sast_iac | false
          :container_scanning | false
          :cluster_image_scanning | false
          :dependency_scanning | false
          :license_scanning | false
          :secret_detection | true
          :coverage_fuzzing | false
          :api_fuzzing | false
          :corpus_management | true
        end

        with_them do
          it 'reports that all scanners are configured for which latest pipeline has builds' do
            feature = features.find { |scan| scan['type'] == type.to_s }

            expect(feature['configured']).to eq(configured)
          end
        end
      end
    end

    context 'when the project has no default branch pipeline' do
      let_it_be(:project) { create(:project, :repository) }

      it 'reports that auto devops is disabled' do
        expect(html_data[:auto_devops_enabled]).to be_falsy
      end

      it 'includes a link to CI pipeline docs' do
        expect(html_data[:latest_pipeline_path]).to eq(help_page_path('ci/pipelines/_index.md'))
      end

      context 'when gathering feature data' do
        let(:features) { Gitlab::Json.parse(html_data[:features]) }

        where(:type, :configured) do
          :dast | false
          :dast_profiles | true
          :sast | false
          :sast_iac | false
          :container_scanning | false
          :cluster_image_scanning | false
          :dependency_scanning | false
          :license_scanning | false
          :secret_detection | false
          :coverage_fuzzing | false
          :api_fuzzing | false
          :corpus_management | true
        end

        with_them do
          it 'reports all security jobs as unconfigured with exception of "fake" jobs' do
            feature = features.find { |scan| scan['type'] == type.to_s }

            expect(feature['configured']).to eq(configured)
          end
        end
      end
    end

    describe 'secret_push_protection' do
      let_it_be(:project) { create(:project, :repository) }
      let(:features) { Gitlab::Json.parse(html_data[:features]) }

      it 'feature includes secret_push_protection' do
        skip unless Gitlab.ee?

        feature = features.find { |scan| scan["type"] == 'secret_push_protection' }
        expect(feature).not_to be_nil
      end
    end

    def licensed_scan_types
      ::Security::SecurityJobsFinder.allowed_job_types + ::Security::LicenseComplianceJobsFinder.allowed_job_types - [:cluster_image_scanning]
    end
  end
end

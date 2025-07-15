# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectCiCdSetting, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  describe 'validations' do
    let(:project) { build(:project) }

    subject { described_class.new(project: project) }

    it 'validates default_git_depth is between 0 and 1000 or nil' do
      expect(subject).to validate_numericality_of(:default_git_depth)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(1000)
        .allow_nil
    end

    it 'validates id_token_sub_claim_components with minimum length 1' do
      subject.id_token_sub_claim_components = []
      expect(subject).not_to be_valid
      expect(subject.errors[:id_token_sub_claim_components]).to include("is too short (minimum is 1 character)")
    end

    it 'validates id_token_sub_claim_components with project_path in the beginning' do
      subject.id_token_sub_claim_components = ['ref']
      expect(subject).not_to be_valid
      expect(subject.errors[:id_token_sub_claim_components])
        .to include("project_path must be the first element of the sub claim")
    end

    it 'validates invalid claim name' do
      subject.id_token_sub_claim_components = %w[project_path not_existing_claim]
      expect(subject).not_to be_valid
      expect(subject.errors[:id_token_sub_claim_components])
        .to include("not_existing_claim is not an allowed sub claim component")
    end

    it 'validates delete_pipelines_in_seconds' do
      is_expected.to validate_numericality_of(:delete_pipelines_in_seconds)
        .only_integer
        .is_greater_than_or_equal_to(ChronicDuration.parse('1 day'))
        .is_less_than_or_equal_to(ChronicDuration.parse('1 year'))
        .with_message('must be between 1 day and 1 year')
    end

    context 'with custom delete_pipelines_in_seconds limits' do
      let(:limit) { ChronicDuration.parse('3 years, 2 months, 1 day') }

      before do
        stub_application_setting(ci_delete_pipelines_in_seconds_limit: limit)
      end

      it 'validates delete_pipelines_in_seconds' do
        is_expected.to validate_numericality_of(:delete_pipelines_in_seconds)
          .only_integer
          .is_greater_than_or_equal_to(ChronicDuration.parse('1 day'))
          .is_less_than_or_equal_to(limit)
          .with_message('must be between 1 day and 38 months 16 days 18 hours')
      end
    end
  end

  describe '#pipeline_variables_minimum_override_role' do
    shared_examples 'enables restrict_user_defined_variables' do |role|
      let(:setting) { described_class.new(project: project) }

      it 'enables restrict_user_defined_variables' do
        setting.pipeline_variables_minimum_override_role = role if role

        expect(project.restrict_user_defined_variables?).to be_truthy
      end
    end

    shared_examples 'disables restrict_user_defined_variables' do |role|
      let(:setting) { described_class.new(project: project) }

      it 'disables restrict_user_defined_variables' do
        setting.pipeline_variables_minimum_override_role = role if role

        expect(project.restrict_user_defined_variables?).to be_falsey
      end
    end

    shared_examples 'sets the default ci_pipeline_variables_minimum_override_role' do |expected_role|
      it "sets ci_pipeline_variables_minimum_override_role to #{expected_role}" do
        expect(project.ci_pipeline_variables_minimum_override_role).to eq(expected_role)
      end
    end

    context 'when restrict_user_defined_variables is false' do
      let(:project) { build(:project) }
      let(:setting) { described_class.new(project: project) }

      before do
        setting.pipeline_variables_minimum_override_role = :maintainer
        setting.restrict_user_defined_variables = false
      end

      it_behaves_like 'sets the default ci_pipeline_variables_minimum_override_role', 'developer'
    end

    context 'when restrict_user_defined_variables is true' do
      let(:project) { build(:project) }
      let(:setting) { described_class.new(project: project) }

      before do
        setting.pipeline_variables_minimum_override_role = :maintainer
      end

      it 'returns the set role' do
        expect(setting.pipeline_variables_minimum_override_role).to eq('maintainer')
      end
    end

    context 'when a namespace is defined' do
      let(:project) { create(:project, :with_namespace_settings) }

      it_behaves_like 'sets the default ci_pipeline_variables_minimum_override_role', 'developer'

      it_behaves_like 'enables restrict_user_defined_variables', 'maintainer'
      it_behaves_like 'disables restrict_user_defined_variables', 'developer'

      context 'when application setting `pipeline_variables_default_allowed` is false' do
        before do
          stub_application_setting(pipeline_variables_default_allowed: false)
        end

        it_behaves_like 'sets the default ci_pipeline_variables_minimum_override_role', 'no_one_allowed'
      end
    end

    context 'when a namespace is not defined' do
      let_it_be(:project) { create(:project) }

      it_behaves_like 'sets the default ci_pipeline_variables_minimum_override_role', 'developer'

      it_behaves_like 'enables restrict_user_defined_variables', 'maintainer'
      it_behaves_like 'disables restrict_user_defined_variables', 'developer'
    end

    context 'when application setting `pipeline_variables_default_allowed` is true' do
      before do
        stub_application_setting(pipeline_variables_default_allowed: true)
      end

      context 'and a namespace is defined' do
        let(:project) { create(:project, :with_namespace_settings) }

        it_behaves_like 'sets the default ci_pipeline_variables_minimum_override_role', 'developer'

        it_behaves_like 'enables restrict_user_defined_variables', 'maintainer'
        it_behaves_like 'disables restrict_user_defined_variables', 'developer'
      end

      context 'and a namespace is not defined' do
        let(:project) { create(:project) }

        it_behaves_like 'sets the default ci_pipeline_variables_minimum_override_role', 'developer'

        it_behaves_like 'enables restrict_user_defined_variables', 'maintainer'
        it_behaves_like 'disables restrict_user_defined_variables', 'developer'
      end
    end
  end

  describe '#pipeline_variables_minimum_override_role=' do
    let(:project) { build(:project) }
    let(:setting) { described_class.new(project: project) }

    context 'when setting a value' do
      before do
        setting.pipeline_variables_minimum_override_role = 'developer'
      end

      it 'sets the role' do
        expect(setting.pipeline_variables_minimum_override_role_for_database).to eq(described_class::DEVELOPER_ROLE)
      end

      it 'disables restrict_user_defined_variables' do
        expect(setting.restrict_user_defined_variables?).to be false
      end
    end

    context 'when setting nil value' do
      before do
        setting.pipeline_variables_minimum_override_role = nil
      end

      it 'does not change the current settings' do
        expect(setting.restrict_user_defined_variables?).to be true
      end
    end
  end

  describe '#id_token_sub_claim_components' do
    it 'is project_path, ref_type, ref by default' do
      expect(described_class.new.id_token_sub_claim_components).to eq(%w[project_path ref_type ref])
    end
  end

  describe '#forward_deployment_enabled' do
    it 'is true by default' do
      expect(described_class.new.forward_deployment_enabled).to be_truthy
    end
  end

  describe '#push_repository_for_job_token_allowed' do
    it 'is false by default' do
      expect(described_class.new.push_repository_for_job_token_allowed).to be_falsey
    end
  end

  describe '#separated_caches' do
    it 'is true by default' do
      expect(described_class.new.separated_caches).to be_truthy
    end
  end

  describe '#default_for_inbound_job_token_scope_enabled' do
    it { is_expected.to be_inbound_job_token_scope_enabled }
  end

  describe '#default_git_depth' do
    let(:default_value) { described_class::DEFAULT_GIT_DEPTH }
    let_it_be(:project) { create(:project) }

    it 'sets default value for new records' do
      expect(project.ci_cd_settings.default_git_depth).to eq(default_value)
    end

    it 'does not set default value if present' do
      project.build_ci_cd_settings(default_git_depth: 0)
      project.save!

      expect(project.reload.ci_cd_settings.default_git_depth).to eq(0)
    end
  end

  describe '#keep_latest_artifacts_available?' do
    let(:attrs) { { keep_latest_artifact: project_enabled } }
    let(:project_settings) { described_class.new(attrs) }

    subject { project_settings.keep_latest_artifacts_available? }

    context 'without application setting record' do
      where(:project_enabled, :result_keep_latest_artifact) do
        false        | false
        true         | true
      end

      with_them do
        it { expect(subject).to eq(result_keep_latest_artifact) }
      end
    end

    context 'with application setting record' do
      where(:instance_enabled, :project_enabled, :result_keep_latest_artifact) do
        false         | false        | false
        false         | true         | false
        true          | false        | false
        true          | true         | true
      end

      before do
        Gitlab::CurrentSettings.current_application_settings.update!(keep_latest_artifact: instance_enabled)
      end

      with_them do
        it { expect(subject).to eq(result_keep_latest_artifact) }
      end
    end
  end

  describe '.configured_to_delete_old_pipelines' do
    let_it_be(:project) { create(:project, ci_delete_pipelines_in_seconds: 2.weeks.to_i) }
    let_it_be(:other_project) { create(:project, group_runners_enabled: true) }

    it 'includes settings with values present' do
      expect(described_class.configured_to_delete_old_pipelines).to contain_exactly(project.ci_cd_settings)
    end
  end
end

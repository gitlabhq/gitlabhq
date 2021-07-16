# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectCiCdSetting do
  using RSpec::Parameterized::TableSyntax

  describe 'validations' do
    it 'validates default_git_depth is between 0 and 1000 or nil' do
      expect(subject).to validate_numericality_of(:default_git_depth)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(1000)
        .allow_nil
    end
  end

  describe '#forward_deployment_enabled' do
    it 'is true by default' do
      expect(described_class.new.forward_deployment_enabled).to be_truthy
    end
  end

  describe '#job_token_scope_enabled' do
    it 'is false by default' do
      expect(described_class.new.job_token_scope_enabled).to be_falsey
    end
  end

  describe '#default_git_depth' do
    let(:default_value) { described_class::DEFAULT_GIT_DEPTH }

    it 'sets default value for new records' do
      project = create(:project)

      expect(project.ci_cd_settings.default_git_depth).to eq(default_value)
    end

    it 'does not set default value if present' do
      project = build(:project)
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
end

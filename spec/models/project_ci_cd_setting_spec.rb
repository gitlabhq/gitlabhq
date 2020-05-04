# frozen_string_literal: true

require 'spec_helper'

describe ProjectCiCdSetting do
  describe '.available?' do
    before do
      described_class.reset_column_information
    end

    it 'returns true' do
      expect(described_class).to be_available
    end

    it 'memoizes the schema version' do
      expect(ActiveRecord::Migrator)
        .to receive(:current_version)
        .and_call_original
        .once

      2.times { described_class.available? }
    end
  end

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
end

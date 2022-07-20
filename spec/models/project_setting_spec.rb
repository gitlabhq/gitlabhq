# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectSetting, type: :model do
  using RSpec::Parameterized::TableSyntax
  it { is_expected.to belong_to(:project) }

  describe 'scopes' do
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_setting_1) { create(:project_setting, project: project_1) }
    let_it_be(:project_setting_2) { create(:project_setting, project: project_2) }

    it 'returns project setting for the given projects' do
      expect(described_class.for_projects(project_1)).to contain_exactly(project_setting_1)
    end
  end

  describe 'validations' do
    it { is_expected.not_to allow_value(nil).for(:target_platforms) }
    it { is_expected.to allow_value([]).for(:target_platforms) }

    it 'allows any combination of the allowed target platforms' do
      valid_target_platform_combinations.each do |target_platforms|
        expect(subject).to allow_value(target_platforms).for(:target_platforms)
      end
    end

    [nil, 'not_allowed', :invalid].each do |invalid_value|
      it { is_expected.not_to allow_value([invalid_value]).for(:target_platforms) }
    end
  end

  describe 'target_platforms=' do
    it 'stringifies and sorts' do
      project_setting = build(:project_setting, target_platforms: [:watchos, :ios])
      expect(project_setting.target_platforms).to eq %w(ios watchos)
    end
  end

  describe '#human_squash_option' do
    where(:squash_option, :human_squash_option) do
      'never'       | 'Do not allow'
      'always'      | 'Require'
      'default_on'  | 'Encourage'
      'default_off' | 'Allow'
    end

    with_them do
      let(:project_setting) { create(:project_setting, squash_option: ProjectSetting.squash_options[squash_option]) }

      subject { project_setting.human_squash_option }

      it { is_expected.to eq(human_squash_option) }
    end
  end

  def valid_target_platform_combinations
    target_platforms = described_class::ALLOWED_TARGET_PLATFORMS

    0.upto(target_platforms.size).flat_map do |n|
      target_platforms.permutation(n).to_a
    end
  end
end

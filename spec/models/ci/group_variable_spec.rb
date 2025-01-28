# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::GroupVariable, feature_category: :ci_variables do
  let_it_be_with_refind(:group) { create(:group) }

  subject { build(:ci_group_variable, group: group) }

  it_behaves_like "CI variable"
  it_behaves_like 'includes Limitable concern'

  it { is_expected.to include_module(Presentable) }
  it { is_expected.to include_module(Ci::Maskable) }
  it { is_expected.to include_module(Ci::HidableVariable) }
  it { is_expected.to include_module(HasEnvironmentScope) }

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:key).scoped_to([:group_id, :environment_scope]).with_message(/\(\w+\) has already been taken/) }
    it { is_expected.to allow_values('').for(:description) }
    it { is_expected.to allow_values(nil).for(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
  end

  describe '.by_environment_scope' do
    let!(:matching_variable) { create(:ci_group_variable, environment_scope: 'production ') }
    let!(:non_matching_variable) { create(:ci_group_variable, environment_scope: 'staging') }

    subject { described_class.by_environment_scope('production') }

    it { is_expected.to contain_exactly(matching_variable) }
  end

  describe '.unprotected' do
    subject { described_class.unprotected }

    context 'when variable is protected' do
      before do
        create(:ci_group_variable, :protected)
      end

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end

    context 'when variable is not protected' do
      let(:variable) { create(:ci_group_variable, protected: false) }

      it 'returns the variable' do
        is_expected.to contain_exactly(variable)
      end
    end
  end

  describe '.for_groups' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_variable) { create(:ci_group_variable, group: group) }
    let_it_be(:other_variable) { create(:ci_group_variable) }

    it { expect(described_class.for_groups([group.id])).to eq([group_variable]) }
  end

  describe '.for_environment_scope_like' do
    let_it_be(:group) { create(:group) }
    let_it_be(:variable1_on_staging1) { create(:ci_group_variable, group: group, environment_scope: 'staging1') }
    let_it_be(:variable2_on_staging2) { create(:ci_group_variable, group: group, environment_scope: 'staging2') }
    let_it_be(:variable3_on_production) { create(:ci_group_variable, group: group, environment_scope: 'production') }

    it {
      expect(described_class.for_environment_scope_like('staging'))
        .to match_array([variable1_on_staging1, variable2_on_staging2])
    }

    it {
      expect(described_class.for_environment_scope_like('production'))
        .to match_array([variable3_on_production])
    }
  end

  describe '.environment_scope_names' do
    let_it_be(:group) { create(:group) }
    let_it_be(:variable1_on_staging1) { create(:ci_group_variable, group: group, environment_scope: 'staging1') }
    let_it_be(:variable2_on_staging2) { create(:ci_group_variable, group: group, environment_scope: 'staging2') }
    let_it_be(:variable3_on_staging2) { create(:ci_group_variable, group: group, environment_scope: 'staging2') }
    let_it_be(:variable4_on_production) { create(:ci_group_variable, group: group, environment_scope: 'production') }

    it 'groups and orders' do
      expect(described_class.environment_scope_names)
        .to match_array(%w[production staging1 staging2])
    end
  end

  describe 'sort_by_attribute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:environment_scope) { 'env_scope' }
    let_it_be(:variable1) { create(:ci_group_variable, key: 'd_var', group: group, environment_scope: environment_scope, created_at: 4.days.ago) }
    let_it_be(:variable2) { create(:ci_group_variable, key: 'a_var', group: group, environment_scope: environment_scope, created_at: 3.days.ago) }
    let_it_be(:variable3) { create(:ci_group_variable, key: 'c_var', group: group, environment_scope: environment_scope, created_at: 2.days.ago) }
    let_it_be(:variable4) { create(:ci_group_variable, key: 'b_var', group: group, environment_scope: environment_scope, created_at: 1.day.ago) }

    let(:sort_by_attribute) { described_class.sort_by_attribute(method).pluck(:key) }

    describe '.created_at_asc' do
      let(:method) { 'created_at_asc' }

      it 'order by created_at ascending' do
        expect(sort_by_attribute).to eq(%w[d_var a_var c_var b_var])
      end
    end

    describe '.created_at_desc' do
      let(:method) { 'created_at_desc' }

      it 'order by created_at descending' do
        expect(sort_by_attribute).to eq(%w[b_var c_var a_var d_var])
      end
    end

    describe '.key_asc' do
      let(:method) { 'key_asc' }

      it 'order by key ascending' do
        expect(sort_by_attribute).to eq(%w[a_var b_var c_var d_var])
      end
    end

    describe '.key_desc' do
      let(:method) { 'key_desc' }

      it 'order by key descending' do
        expect(sort_by_attribute).to eq(%w[d_var c_var b_var a_var])
      end
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_group_variable) }

    let!(:parent) { model.group }
  end

  describe '#audit_details' do
    it "equals to the group variable's key" do
      expect(subject.audit_details).to eq(subject.key)
    end
  end

  describe '#group_name' do
    it "equals to the name of the group the variable belongs to" do
      expect(subject.group_name).to eq(subject.group.name)
    end
  end

  describe '#group_ci_cd_settings_path' do
    it "equals to the path of the CI/CD settings of the group the variable belongs to" do
      expect(subject.group_ci_cd_settings_path).to eq(Gitlab::Routing.url_helpers.group_settings_ci_cd_path(subject.group))
    end
  end
end

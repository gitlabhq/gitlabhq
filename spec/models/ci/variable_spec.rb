# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Variable, feature_category: :ci_variables do
  let_it_be_with_reload(:project) { create(:project) }

  subject { build(:ci_variable, project: project) }

  it_behaves_like "CI variable"
  it_behaves_like 'includes Limitable concern'

  describe 'validations' do
    it { is_expected.to include_module(Presentable) }
    it { is_expected.to include_module(Ci::Maskable) }
    it { is_expected.to include_module(Ci::HidableVariable) }
    it { is_expected.to include_module(HasEnvironmentScope) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:project_id, :environment_scope).with_message(/\(\w+\) has already been taken/) }
    it { is_expected.to allow_values('').for(:description) }
    it { is_expected.to allow_values(nil).for(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
  end

  describe '.by_environment_scope' do
    let!(:matching_variable) { create(:ci_variable, environment_scope: 'production ') }
    let!(:non_matching_variable) { create(:ci_variable, environment_scope: 'staging') }

    subject { described_class.by_environment_scope('production') }

    it { is_expected.to contain_exactly(matching_variable) }
  end

  describe '.unprotected' do
    subject { described_class.unprotected }

    context 'when variable is protected' do
      before do
        create(:ci_variable, :protected)
      end

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end

    context 'when variable is not protected' do
      let(:variable) { create(:ci_variable, protected: false) }

      it 'returns the variable' do
        is_expected.to contain_exactly(variable)
      end
    end
  end

  context 'loose foreign key on ci_variables.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project, namespace: create(:group)) }
      let!(:model) { create(:ci_variable, project: parent) }
    end
  end

  describe '#audit_details' do
    it "equals to the variable's key" do
      expect(subject.audit_details).to eq(subject.key)
    end
  end
end

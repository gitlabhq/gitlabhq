# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::GroupVariable do
  subject { build(:ci_group_variable) }

  it_behaves_like "CI variable"

  it { is_expected.to include_module(Presentable) }
  it { is_expected.to include_module(Ci::Maskable) }
  it { is_expected.to include_module(HasEnvironmentScope) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to([:group_id, :environment_scope]).with_message(/\(\w+\) has already been taken/) }

  describe '.by_environment_scope' do
    let!(:matching_variable) { create(:ci_group_variable, environment_scope: 'production ') }
    let!(:non_matching_variable) { create(:ci_group_variable, environment_scope: 'staging') }

    subject { Ci::GroupVariable.by_environment_scope('production') }

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
end

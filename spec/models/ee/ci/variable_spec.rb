require 'spec_helper'

describe Ci::Variable, models: true do
  subject { build(:ci_variable) }

  context 'when variable_environment_scope available' do
    before do
      stub_feature(:variable_environment_scope, true)
    end

    it { is_expected.to allow_value('*').for(:environment_scope) }
    it { is_expected.to allow_value('review/*').for(:environment_scope) }
    it { is_expected.not_to allow_value('').for(:environment_scope) }

    it do
      is_expected.to validate_uniqueness_of(:key)
        .scoped_to(:project_id, :environment_scope)
    end
  end

  context 'when variable_environment_scope unavailable' do
    before do
      stub_feature(:variable_environment_scope, false)
    end

    it { is_expected.to allow_value('*').for(:environment_scope) }

    it 'ignores the changes to environment_scope' do
      expect do
        subject.update!(environment_scope: 'review/*')
      end.not_to change { subject.environment_scope }
    end
  end
end

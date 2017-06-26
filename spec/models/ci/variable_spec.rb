require 'spec_helper'

describe Ci::Variable, models: true do
  subject { build(:ci_variable) }

  it { is_expected.to be_kind_of(HasVariable) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:project_id) }

  describe 'validates :key' do
    let(:project) { create(:project) }

    it 'be invalid if it exceeds maximum' do
      expect do
        create(:ci_variable, project: project, key: "A"*256)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'be invalid if violates constraints' do
      expect do
        create(:ci_variable, project: project, key: "*")
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'when there is a variable' do
      before do
        create(:ci_variable, key: 'AAA', project: project)
      end

      it 'be valid if it is unique' do
        expect do
          create(:ci_variable, project: project, key: 'CCC')
        end.not_to raise_error
      end

      it 'be invalid if it is duplicated' do
        expect do
          create(:ci_variable, project: project, key: 'AAA')
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
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
end

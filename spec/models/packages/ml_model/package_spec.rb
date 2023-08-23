# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MlModel::Package, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:ml_model) { create(:ml_model_package, project: project) }
  let_it_be(:generic_package) { create(:generic_package, project: project) }

  describe 'associations' do
    it { is_expected.to have_one(:model_version) }
  end

  describe 'all' do
    it 'fetches only ml_model packages' do
      expect(described_class.all).to eq([ml_model])
    end
  end

  describe '#valid?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:valid_version) { '1.0.0' }
    let_it_be(:valid_name) { 'some_model' }

    let(:version) { valid_version }
    let(:name) { valid_name }

    let(:ml_model) { described_class.new(version: version, name: name, project: project) }

    subject(:errors) do
      ml_model.validate
      ml_model.errors
    end

    it { expect(ml_model).to validate_presence_of(:name) }
    it { expect(ml_model).to validate_presence_of(:version) }

    it 'validates a valid ml_model package' do
      expect(errors).to be_empty
    end

    describe 'name' do
      where(:ctx, :name) do
        'name is blank'                     | ''
        'name is nil'                       | nil
        'name is not valid package name'    | '!!()()'
        'name is too large'                 | ('a' * 256)
      end
      with_them do
        it { expect(errors).to include(:name) }
      end
    end

    describe 'version' do
      where(:ctx, :version) do
        'version is blank'            | ''
        'version is nil'              | nil
        'version is not valid semver' | 'v1.0.0'
        'version is too large'        | ('a' * 256)
      end
      with_them do
        it { expect(errors).to include(:version) }
      end
    end
  end
end

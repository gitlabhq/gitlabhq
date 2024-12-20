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

    context 'when name' do
      where(:case_name, :name) do
        'is blank'                     | ''
        'is nil'                       | nil
        'is not valid package name'    | '!!()()'
        'is too large'                 | ('a' * 256)
      end
      with_them do
        it 'is invalid' do
          expect(errors).to include(:name)
        end
      end
    end

    context 'when version' do
      where(:case_name, :version) do
        'is semver'            | '1.2.0-rc.1+metadata'
        'is candidate_(id)'    | 'candidate_123'
      end
      with_them do
        it 'is valid' do
          expect(errors).not_to include(:version)
        end
      end

      where(:case_name, :version) do
        'is blank'            | ''
        'is nil'              | nil
        'is not valid semver' | 'v1.0.0'
        'is too large'        | ('a' * 256)
      end
      with_them do
        it 'is invalid' do
          expect(errors).to include(:version)
        end
      end
    end
  end

  describe '.installable' do
    it_behaves_like 'installable packages', :ml_model_package
  end

  describe '#publish_creation_event' do
    let_it_be(:project) { create(:project) }

    let(:version) { 'candidate_42' }

    subject(:create_package) { described_class.create!(project: project, name: 'incoming', version: version) }

    it 'publishes an event' do
      expect { create_package }
        .to publish_event(::Packages::PackageCreatedEvent)
              .with({
                project_id: project.id,
                id: kind_of(Numeric),
                name: 'incoming',
                version: 'candidate_42',
                package_type: 'ml_model'
              })
    end
  end
end

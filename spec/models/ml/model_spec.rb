# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Model, feature_category: :mlops do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:default_experiment) }
  end

  describe '#valid?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project) }
    let_it_be(:existing_model) { create(:ml_models, name: 'an_existing_model', project: project) }
    let_it_be(:valid_name) { 'a_valid_name' }
    let_it_be(:default_experiment) { create(:ml_experiments, name: valid_name, project: project) }

    let(:name) { valid_name }

    subject(:errors) do
      m = described_class.new(name: name, project: project, default_experiment: default_experiment)
      m.validate
      m.errors
    end

    it 'validates a valid model version' do
      expect(errors).to be_empty
    end

    describe 'name' do
      where(:ctx, :name) do
        'name is blank'                     | ''
        'name is not valid package name'    | '!!()()'
        'name is too large'                 | ('a' * 256)
        'name is not unique in the project' | 'an_existing_model'
      end
      with_them do
        it { expect(errors).to include(:name) }
      end
    end

    describe 'default_experiment' do
      context 'when experiment name name is different than model name' do
        before do
          allow(default_experiment).to receive(:name).and_return("#{name}a")
        end

        it { expect(errors).to include(:default_experiment) }
      end

      context 'when model version project is different than model project' do
        before do
          allow(default_experiment).to receive(:project_id).and_return(project.id + 1)
        end

        it { expect(errors).to include(:default_experiment) }
      end
    end
  end
end

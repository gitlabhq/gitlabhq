require 'spec_helper'

describe VariableDuplicatesValidator do
  let(:validator) { described_class.new(attributes: [:variables], **options) }

  describe '#validate_each' do
    let(:project) { build(:project) }

    subject { validator.validate_each(project, :variables, project.variables) }

    context 'with no scope' do
      let(:options) { {} }
      let(:variables) { build_list(:ci_variable, 2, project: project) }

      before do
        project.variables << variables
      end

      it 'does not have any errors' do
        subject

        expect(project.errors.empty?).to be true
      end

      context 'with duplicates' do
        before do
          project.variables.build(key: variables.first.key, value: 'dummy_value')
        end

        it 'has a duplicate key error' do
          subject

          expect(project.errors).to have_key(:variables)
        end
      end
    end

    context 'with a scope attribute' do
      let(:options) { { scope: :environment_scope } }
      let(:first_variable) { build(:ci_variable, key: 'test_key', environment_scope: '*', project: project) }
      let(:second_variable) { build(:ci_variable, key: 'test_key', environment_scope: 'prod', project: project) }

      before do
        project.variables << first_variable
        project.variables << second_variable
      end

      it 'does not have any errors' do
        subject

        expect(project.errors.empty?).to be true
      end

      context 'with duplicates' do
        before do
          project.variables.build(key: second_variable.key, value: 'dummy_value', environment_scope: second_variable.environment_scope)
        end

        it 'has a duplicate key error' do
          subject

          expect(project.errors).to have_key(:variables)
        end
      end
    end
  end
end

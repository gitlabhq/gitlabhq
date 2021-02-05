# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NestedAttributesDuplicatesValidator do
  let(:validator) { described_class.new(attributes: [attribute], **options) }

  describe '#validate_each' do
    let(:project) { build(:project) }
    let(:record) { project }
    let(:attribute) { :variables }
    let(:value) { project.variables }

    subject { validator.validate_each(record, attribute, value) }

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

    context 'with a child attribute' do
      let(:release) { build(:release) }
      let(:first_link) { build(:release_link, name: 'test1', url: 'https://www.google1.com', release: release) }
      let(:second_link) { build(:release_link, name: 'test2', url: 'https://www.google2.com', release: release) }
      let(:record) { release }
      let(:attribute) { :links }
      let(:value) { release.links }
      let(:options) { { scope: :release, child_attributes: %i[name url] } }

      before do
        release.links << first_link
        release.links << second_link
      end

      it 'does not have any errors' do
        subject

        expect(release.errors.empty?).to be true
      end

      context 'when name is duplicated' do
        let(:second_link) { build(:release_link, name: 'test1', release: release) }

        it 'has a duplicate error' do
          subject

          expect(release.errors).to have_key(attribute)
        end
      end

      context 'when url is duplicated' do
        let(:second_link) { build(:release_link, url: 'https://www.google1.com', release: release) }

        it 'has a duplicate error' do
          subject

          expect(release.errors).to have_key(attribute)
        end
      end
    end
  end
end

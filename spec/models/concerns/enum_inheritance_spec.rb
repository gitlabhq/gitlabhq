# frozen_string_literal: true

require 'spec_helper'

module EnumInheritableTestCase
  class Animal < ActiveRecord::Base
    include EnumInheritance

    def self.table_name = '_test_animals'
    def self.inheritance_column = 'species'

    enum species: {
      dog: 1,
      cat: 2,
      bird: 3
    }

    def self.inheritance_column_to_class_map = {
      dog: 'EnumInheritableTestCase::Dog',
      cat: 'EnumInheritableTestCase::Cat'
    }.freeze
  end

  class Dog < Animal; end
  class Cat < Animal; end
end

RSpec.describe EnumInheritance, feature_category: :shared do
  describe '.sti_class_to_enum_map' do
    it 'is the inverse of sti_class_to_enum_map' do
      expect(EnumInheritableTestCase::Animal.sti_class_to_enum_map).to include({
        'EnumInheritableTestCase::Dog' => :dog,
        'EnumInheritableTestCase::Cat' => :cat
      })
    end
  end

  describe '.sti_class_for' do
    it 'is the base class if no mapping for type is provided' do
      expect(EnumInheritableTestCase::Animal.sti_class_for('bird')).to be(EnumInheritableTestCase::Animal)
    end

    it 'is class if mapping for type is provided' do
      expect(EnumInheritableTestCase::Animal.sti_class_for('dog')).to be(EnumInheritableTestCase::Dog)
    end
  end

  describe '.sti_name' do
    it 'is nil if map does not exist' do
      expect(EnumInheritableTestCase::Animal.sti_name).to eq("")
    end

    it 'is nil if map exists' do
      expect(EnumInheritableTestCase::Dog.sti_name).to eq("dog")
    end
  end

  describe 'querying' do
    before_all do
      EnumInheritableTestCase::Animal.connection.execute(<<~SQL)
        CREATE TABLE _test_animals (
                    id bigserial primary key not null,
                    species bigint not null
        );
      SQL
    end

    let_it_be(:dog) { EnumInheritableTestCase::Dog.create! }
    let_it_be(:cat) { EnumInheritableTestCase::Cat.create! }
    let_it_be(:bird) { EnumInheritableTestCase::Animal.create!(species: :bird) }

    describe 'object class when querying' do
      context  'when mapping for type exists' do
        it 'is the super class', :aggregate_failures do
          queried_dog = EnumInheritableTestCase::Animal.find_by(id: dog.id)
          expect(queried_dog).to eq(dog)
          # Test below is already part of the test above, but it makes the desired behavior explicit
          expect(queried_dog.class).to eq(EnumInheritableTestCase::Dog)

          queried_cat = EnumInheritableTestCase::Animal.find_by(id: cat.id)
          expect(queried_cat).to eq(cat)
          expect(queried_cat.class).to eq(EnumInheritableTestCase::Cat)
        end
      end

      context  'when mapping does not exist' do
        it 'is the base class' do
          expect(EnumInheritableTestCase::Animal.find_by(id: bird.id).class).to eq(EnumInheritableTestCase::Animal)
        end
      end
    end

    it 'finds by type' do
      expect(EnumInheritableTestCase::Animal.where(species: :dog).first!).to eq(dog)
    end
  end
end

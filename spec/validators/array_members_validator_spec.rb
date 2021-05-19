# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ArrayMembersValidator do
  using RSpec::Parameterized::TableSyntax

  child_class = Class.new

  subject(:test_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      attr_accessor :children
      validates :children, array_members: { member_class: child_class }
    end
  end

  where(:children, :is_valid) do
    [child_class.new]                | true
    [Class.new.new]                  | false
    [child_class.new, Class.new.new] | false
    []                               | false
    child_class.new                  | false
    [Class.new(child_class).new]     | false
  end

  with_them do
    it 'only accepts valid children nodes' do
      expect(test_class.new(children: children).valid?).to eq(is_valid)
    end
  end

  context 'validation message' do
    subject(:test_class) do
      Class.new do
        include ActiveModel::Model
        include ActiveModel::Validations
        attr_accessor :children
      end
    end

    context 'with default object name' do
      it 'uses attribute name', :aggregate_failures do
        test_class.class_eval do
          validates :children, array_members: { member_class: child_class }
        end

        object = test_class.new(children: [])

        expect(object.valid?).to be_falsey
        expect(object.errors.messages).to eq(children: ['should be an array of children objects'])
      end
    end

    context 'with custom object name' do
      it 'uses that name', :aggregate_failures do
        test_class.class_eval do
          validates :children, array_members: { member_class: child_class, object_name: 'test' }
        end

        object = test_class.new(children: [])

        expect(object.valid?).to be_falsey
        expect(object.errors.messages).to eq(children: ['should be an array of test objects'])
      end
    end
  end
end

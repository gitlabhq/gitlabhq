require 'spec_helper'

describe IgnorableColumn do
  let :base_class do
    Class.new do
      def self.columns
        # This method does not have access to "double"
        [
          Struct.new(:name).new('id'),
          Struct.new(:name).new('title'),
          Struct.new(:name).new('date')
        ]
      end
    end
  end

  let :model do
    Class.new(base_class) do
      include IgnorableColumn
    end
  end

  describe '.columns' do
    it 'returns the columns, excluding the ignored ones' do
      model.ignore_column(:title, :date)

      expect(model.columns.map(&:name)).to eq(%w(id))
    end
  end

  describe '.ignored_columns' do
    it 'returns a Set' do
      expect(model.ignored_columns).to be_an_instance_of(Set)
    end

    it 'returns the names of the ignored columns' do
      model.ignore_column(:title, :date)

      expect(model.ignored_columns).to eq(Set.new(%w(title date)))
    end
  end
end

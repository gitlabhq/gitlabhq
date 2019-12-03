# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::ObsoleteIgnoredColumns do
  module Testing
    class MyBase < ApplicationRecord
    end

    class SomeAbstract < MyBase
      include IgnorableColumns

      self.abstract_class = true

      self.table_name = 'projects'

      ignore_column :unused, remove_after: '2019-01-01', remove_with: '12.0'
    end

    class B < MyBase
      include IgnorableColumns

      self.table_name = 'issues'

      ignore_column :id, :other, remove_after: '2019-01-01', remove_with: '12.0'
      ignore_column :not_used_but_still_ignored, remove_after: Date.today.to_s, remove_with: '12.1'
    end

    class A < SomeAbstract
      ignore_column :also_unused, remove_after: '2019-02-01', remove_with: '12.1'
      ignore_column :not_used_but_still_ignored, remove_after: Date.today.to_s, remove_with: '12.1'
    end

    class C < MyBase
      self.table_name = 'users'
    end
  end

  subject { described_class.new(Testing::MyBase) }

  describe '#execute' do
    it 'returns a list of class names and columns pairs' do
      expect(subject.execute).to eq([
        ['Testing::A', {
          'unused' => IgnorableColumns::ColumnIgnore.new(Date.parse('2019-01-01'), '12.0'),
          'also_unused' => IgnorableColumns::ColumnIgnore.new(Date.parse('2019-02-01'), '12.1')
        }],
        ['Testing::B', {
          'other' => IgnorableColumns::ColumnIgnore.new(Date.parse('2019-01-01'), '12.0')
        }]
      ])
    end
  end
end

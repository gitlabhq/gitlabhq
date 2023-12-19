# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::ObsoleteIgnoredColumns, feature_category: :database do
  before do
    stub_const('Testing', Module.new)
    stub_const('Testing::MyBase', Class.new(ActiveRecord::Base))
    stub_const('SomeAbstract', Class.new(Testing::MyBase))
    stub_const('Testing::B', Class.new(Testing::MyBase))
    stub_const('Testing::A', Class.new(SomeAbstract))
    stub_const('Testing::C', Class.new(Testing::MyBase))

    # Used a fixed date to prevent tests failing across date boundaries
    stub_const('REMOVE_DATE', Date.new(2019, 12, 16))

    Testing.module_eval do
      Testing::MyBase.class_eval do
        include IgnorableColumns
      end

      SomeAbstract.class_eval do
        self.abstract_class = true

        self.table_name = 'projects'

        ignore_column :unused, remove_after: '2019-01-01', remove_with: '12.0'
      end

      Testing::B.class_eval do
        self.table_name = 'issues'

        ignore_column :id, :other, remove_after: '2019-01-01', remove_with: '12.0'
        ignore_column :not_used_but_still_ignored, remove_after: REMOVE_DATE.to_s, remove_with: '12.1'
      end

      Testing::A.class_eval do
        ignore_column :also_unused, remove_after: '2019-02-01', remove_with: '12.1'
        ignore_column :not_used_but_still_ignored, remove_after: REMOVE_DATE.to_s, remove_with: '12.1'
      end

      Testing::C.class_eval do
        self.table_name = 'users'
      end
    end
  end

  subject { described_class.new(Testing::MyBase) }

  describe '#execute' do
    it 'returns a list of class names and columns pairs' do
      travel_to(REMOVE_DATE) do
        expect(subject.execute).to eq(
          [
            ['Testing::A', {
              'unused' => IgnorableColumns::ColumnIgnore.new(Date.parse('2019-01-01'), '12.0', false),
              'also_unused' => IgnorableColumns::ColumnIgnore.new(Date.parse('2019-02-01'), '12.1', false)
            }],
            ['Testing::B', {
              'other' => IgnorableColumns::ColumnIgnore.new(Date.parse('2019-01-01'), '12.0', false)
            }]
          ])
      end
    end
  end
end

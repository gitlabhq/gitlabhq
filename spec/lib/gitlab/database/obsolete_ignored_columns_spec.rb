# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::ObsoleteIgnoredColumns do
  module Testing
    class MyBase < ApplicationRecord
    end

    class SomeAbstract < MyBase
      self.abstract_class = true

      self.table_name = 'projects'

      self.ignored_columns += %i[unused]
    end

    class B < MyBase
      self.table_name = 'issues'

      self.ignored_columns += %i[id other]
    end

    class A < SomeAbstract
      self.ignored_columns += %i[id also_unused]
    end

    class C < MyBase
      self.table_name = 'users'
    end
  end

  subject { described_class.new(Testing::MyBase) }

  describe '#execute' do
    it 'returns a list of class names and columns pairs' do
      expect(subject.execute).to eq([
        ['Testing::A', %w(unused also_unused)],
        ['Testing::B', %w(other)]
      ])
    end
  end
end

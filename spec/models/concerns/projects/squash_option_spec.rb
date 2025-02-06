# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::SquashOption, feature_category: :source_code_management do
  let(:test_class) do
    Class.new(ApplicationRecord) do
      include Projects::SquashOption

      self.table_name = 'project_settings'

      def self.name
        'TestClass'
      end
    end
  end

  subject(:instance) { test_class.new }

  describe '#branch_rule' do
    it 'raises NotImplementedError' do
      expect { instance.branch_rule }.to raise_error(NotImplementedError)
    end
  end
end

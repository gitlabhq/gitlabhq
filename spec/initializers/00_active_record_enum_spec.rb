# frozen_string_literal: true

require 'spec_helper'

# Adds a missing test to provide full coverage for the patch
RSpec.describe 'ActiveRecord::Enum Patch', feature_category: :database do
  context 'when enum is not backed by a database column' do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = :projects

        enum values_without_backed_column: [:one, :two]
      end
    end

    it 'does not raise an error' do
      expect do
        klass.new.values_without_backed_column
      end.not_to raise_error
    end
  end
end

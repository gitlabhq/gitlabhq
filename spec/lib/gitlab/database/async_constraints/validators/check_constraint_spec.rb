# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncConstraints::Validators::CheckConstraint, feature_category: :database do
  it_behaves_like 'async constraints validation' do
    let(:constraint_type) { :check_constraint }

    before do
      connection.create_table(table_name) do |t|
        t.integer :parent_id
      end

      connection.execute(<<~SQL.squish)
        ALTER TABLE #{table_name} ADD CONSTRAINT #{constraint_name}
          CHECK ( parent_id = 101 ) NOT VALID;
      SQL
    end
  end
end

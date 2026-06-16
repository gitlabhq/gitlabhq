# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::DeletedRecord, type: :model, feature_category: :database do
  it_behaves_like 'a loose foreign key record that includes DeletedRecordConcern class methods' do
    let_it_be(:deleted_record_1) do
      described_class.create!(fully_qualified_table_name: table, primary_key_value: 5, cleanup_attempts: 2)
    end

    let_it_be(:deleted_record_2) do
      described_class.create!(fully_qualified_table_name: table, primary_key_value: 1, cleanup_attempts: 0)
    end

    let_it_be(:deleted_record_3) do
      described_class.create!(fully_qualified_table_name: 'public.other_table', primary_key_value: 3)
    end

    let_it_be(:deleted_record_4) do
      described_class.create!(fully_qualified_table_name: table, primary_key_value: 1, cleanup_attempts: 1)
    end
  end

  it_behaves_like 'a loose foreign key record that includes DeletedRecordConcern sliding list partitioning'
end

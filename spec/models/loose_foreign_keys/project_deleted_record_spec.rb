# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::ProjectDeletedRecord, feature_category: :database do
  let_it_be(:project) { create(:project) }

  it_behaves_like 'a loose foreign key record that includes DeletedRecordConcern class methods' do
    let_it_be(:deleted_record_1) do
      described_class.create!(
        fully_qualified_table_name: table, primary_key_value: 5, cleanup_attempts: 2,
        project_id: project.id, consume_after: 3.hours.ago
      )
    end

    let_it_be(:deleted_record_2) do
      described_class.create!(
        fully_qualified_table_name: table, primary_key_value: 1, cleanup_attempts: 0,
        project_id: project.id, consume_after: 2.hours.ago
      )
    end

    let_it_be(:deleted_record_3) do
      described_class.create!(
        fully_qualified_table_name: 'public.other_table', primary_key_value: 3,
        project_id: project.id, consume_after: 1.hour.ago
      )
    end

    let_it_be(:deleted_record_4) do
      described_class.create!(
        fully_qualified_table_name: table, primary_key_value: 1, cleanup_attempts: 1,
        project_id: project.id, consume_after: Time.current
      )
    end
  end

  it_behaves_like 'a loose foreign key record that includes DeletedRecordConcern sliding list partitioning' do
    let(:sharding_key) { { project_id: project.id } }
  end
end

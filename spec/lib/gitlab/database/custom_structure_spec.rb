# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::CustomStructure do
  let_it_be(:structure) { described_class.new }
  let_it_be(:filepath) { Rails.root.join(described_class::CUSTOM_DUMP_FILE) }
  let_it_be(:file_header) do
    <<~DATA
      -- this file tracks custom GitLab data, such as foreign keys referencing partitioned tables
      -- more details can be found in the issue: https://gitlab.com/gitlab-org/gitlab/-/issues/201872
      SET search_path=public;
    DATA
  end

  let(:io) { StringIO.new }

  before do
    allow(File).to receive(:open).with(filepath, anything).and_yield(io)
  end

  context 'when there are no partitioned_foreign_keys' do
    it 'dumps a valid structure file' do
      structure.dump

      expect(io.string).to eq("#{file_header}\n")
    end
  end

  context 'when there are partitioned_foreign_keys' do
    let!(:first_fk) do
      Gitlab::Database::PartitioningMigrationHelpers::PartitionedForeignKey.create(
        cascade_delete: true, from_table: 'issues', from_column: 'project_id', to_table: 'projects', to_column: 'id')
    end
    let!(:second_fk) do
      Gitlab::Database::PartitioningMigrationHelpers::PartitionedForeignKey.create(
        cascade_delete: false, from_table: 'issues', from_column: 'moved_to_id', to_table: 'issues', to_column: 'id')
    end

    it 'dumps a file with the command to restore the current keys' do
      structure.dump

      expect(io.string).to eq(<<~DATA)
        #{file_header}
        COPY partitioned_foreign_keys (id, cascade_delete, from_table, from_column, to_table, to_column) FROM STDIN;
        #{first_fk.id}\ttrue\tissues\tproject_id\tprojects\tid
        #{second_fk.id}\tfalse\tissues\tmoved_to_id\tissues\tid
        \\.
      DATA

      first_fk.destroy
      io.truncate(0)
      io.rewind

      structure.dump

      expect(io.string).to eq(<<~DATA)
        #{file_header}
        COPY partitioned_foreign_keys (id, cascade_delete, from_table, from_column, to_table, to_column) FROM STDIN;
        #{second_fk.id}\tfalse\tissues\tmoved_to_id\tissues\tid
        \\.
      DATA
    end
  end
end

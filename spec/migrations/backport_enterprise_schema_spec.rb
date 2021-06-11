# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackportEnterpriseSchema, schema: 20190329085614 do
  include MigrationsHelpers

  def drop_if_exists(table)
    active_record_base.connection.drop_table(table) if active_record_base.connection.table_exists?(table)
  end

  describe '#up' do
    it 'creates new EE tables' do
      migrate!

      expect(active_record_base.connection.table_exists?(:epics)).to be true
      expect(active_record_base.connection.table_exists?(:geo_nodes)).to be true
    end

    context 'missing EE columns' do
      before do
        drop_if_exists(:epics)

        active_record_base.connection.create_table "epics" do |t|
          t.integer :group_id, null: false, index: true
          t.integer :author_id, null: false, index: true
        end
      end

      after do
        drop_if_exists(:epics)
      end

      it 'flags an error' do
        expect { migrate! }.to raise_error(/Your database is missing.*that is present for GitLab EE/)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Integrations::StiType do
  let(:types) { ['AsanaService', 'Integrations::Asana', Integrations::Asana] }

  describe '#serialize' do
    context 'SQL SELECT' do
      let(:expected_sql) do
        <<~SQL.strip
          SELECT "integrations".* FROM "integrations" WHERE "integrations"."type" = 'AsanaService'
        SQL
      end

      it 'forms SQL SELECT statements correctly' do
        sql_statements = types.map do |type|
          Integration.where(type: type).to_sql
        end

        expect(sql_statements).to all(eq(expected_sql))
      end
    end

    context 'SQL CREATE' do
      let(:expected_sql) do
        <<~SQL.strip
          INSERT INTO "integrations" ("type") VALUES ('AsanaService')
        SQL
      end

      it 'forms SQL CREATE statements correctly' do
        sql_statements = types.map do |type|
          record = ActiveRecord::QueryRecorder.new { Integration.insert({ type: type }) }
          record.log.first
        end

        expect(sql_statements).to all(include(expected_sql))
      end
    end

    context 'SQL UPDATE' do
      let(:expected_sql) do
        <<~SQL.strip
          UPDATE "integrations" SET "type" = 'AsanaService'
        SQL
      end

      let_it_be(:service) { create(:service) }

      it 'forms SQL UPDATE statements correctly' do
        sql_statements = types.map do |type|
          record = ActiveRecord::QueryRecorder.new { service.update_column(:type, type) }
          record.log.first
        end

        expect(sql_statements).to all(include(expected_sql))
      end
    end

    context 'SQL DELETE' do
      let(:expected_sql) do
        <<~SQL.strip
          DELETE FROM "integrations" WHERE "integrations"."type" = 'AsanaService'
        SQL
      end

      let(:service) { create(:service) }

      it 'forms SQL DELETE statements correctly' do
        sql_statements = types.map do |type|
          record = ActiveRecord::QueryRecorder.new { Integration.delete_by(type: type) }
          record.log.first
        end

        expect(sql_statements).to all(match(expected_sql))
      end
    end
  end

  describe '#deserialize' do
    specify 'it deserializes type correctly', :aggregate_failures do
      types.each do |type|
        service = create(:service, type: type)

        expect(service.type).to eq('AsanaService')
      end
    end
  end

  describe '#cast' do
    it 'casts type as model correctly', :aggregate_failures do
      create(:service, type: 'AsanaService')

      types.each do |type|
        expect(Integration.find_by(type: type)).to be_kind_of(Integrations::Asana)
      end
    end
  end

  describe '#changed?' do
    it 'detects changes correctly', :aggregate_failures do
      service = create(:service, type: 'AsanaService')

      types.each do |type|
        service.type = type

        expect(service).not_to be_changed
      end

      service.type = 'NewType'

      expect(service).to be_changed
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Models::AuditEvent, feature_category: :audit_events do
  let(:instance) { described_class.new }

  describe '#by_entity_type' do
    it 'builds the correct SQL' do
      expected_sql = <<~SQL
        SELECT * FROM "audit_events" WHERE "audit_events"."entity_type" = 'Project'
      SQL

      result_sql = instance.by_entity_type("Project").to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#by_entity_id' do
    it 'builds the correct SQL' do
      expected_sql = <<~SQL
        SELECT * FROM "audit_events" WHERE "audit_events"."entity_id" = 42
      SQL

      result_sql = instance.by_entity_id(42).to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#by_author_id' do
    it 'builds the correct SQL' do
      expected_sql = <<~SQL
        SELECT * FROM "audit_events" WHERE "audit_events"."author_id" = 5
      SQL

      result_sql = instance.by_author_id(5).to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#by_entity_username' do
    let_it_be(:user) { create(:user, username: 'Dummy') }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL
        SELECT * FROM "audit_events" WHERE "audit_events"."entity_id" = #{user.id}
      SQL

      result_sql = instance.by_entity_username('Dummy').to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#by_author_username' do
    let_it_be(:user) { create(:user, username: 'Dummy') }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL
        SELECT * FROM "audit_events" WHERE "audit_events"."author_id" = #{user.id}
      SQL

      result_sql = instance.by_author_username('Dummy').to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe 'class methods' do
    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    describe '.by_entity_type' do
      it 'calls the corresponding instance method' do
        expect(instance).to receive(:by_entity_type).with("Project")

        described_class.by_entity_type("Project")
      end
    end

    describe '.by_entity_id' do
      it 'calls the corresponding instance method' do
        expect(instance).to receive(:by_entity_id).with(42)

        described_class.by_entity_id(42)
      end
    end

    describe '.by_author_id' do
      it 'calls the corresponding instance method' do
        expect(instance).to receive(:by_author_id).with(5)

        described_class.by_author_id(5)
      end
    end

    describe '.by_entity_username' do
      it 'calls the corresponding instance method' do
        expect(instance).to receive(:by_entity_username).with('Dummy')

        described_class.by_entity_username('Dummy')
      end
    end

    describe '.by_author_username' do
      it 'calls the corresponding instance method' do
        expect(instance).to receive(:by_author_username).with('Dummy')

        described_class.by_author_username('Dummy')
      end
    end
  end

  describe 'method chaining' do
    it 'builds the correct SQL with chained methods' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "audit_events"
        WHERE "audit_events"."entity_type" = 'Project'
        AND "audit_events"."author_id" = 1
      SQL

      instance = described_class.new
      result_sql = instance.by_entity_type("Project").by_author_id(1).to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end
end

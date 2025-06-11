# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::SchemaMigrations, feature_category: :database do
  let(:connection) { instance_double(ClickHouse::Connection) }
  let(:database) { :main }

  describe '.touch_all' do
    let(:context) { instance_double(ClickHouse::SchemaMigrations::Context) }
    let(:migrations) { instance_double(ClickHouse::SchemaMigrations::Migrations) }

    before do
      allow(ClickHouse::SchemaMigrations::Context).to receive(:new).with(connection, database).and_return(context)
      allow(ClickHouse::SchemaMigrations::Migrations).to receive(:new).with(context).and_return(migrations)
      allow(migrations).to receive(:touch_all)
    end

    it 'creates context with connection and database' do
      described_class.touch_all(connection, database)

      expect(ClickHouse::SchemaMigrations::Context).to have_received(:new).with(connection, database)
    end

    it 'creates migrations with context and calls touch_all' do
      described_class.touch_all(connection, database)

      expect(ClickHouse::SchemaMigrations::Migrations).to have_received(:new).with(context)
      expect(migrations).to have_received(:touch_all)
    end
  end

  describe '.load_all' do
    let(:context) { instance_double(ClickHouse::SchemaMigrations::Context) }
    let(:migrations) { instance_double(ClickHouse::SchemaMigrations::Migrations) }

    before do
      allow(ClickHouse::SchemaMigrations::Context).to receive(:new).with(connection, database).and_return(context)
      allow(ClickHouse::SchemaMigrations::Migrations).to receive(:new).with(context).and_return(migrations)
      allow(migrations).to receive(:load_all)
    end

    it 'creates context with connection and database' do
      described_class.load_all(connection, database)

      expect(ClickHouse::SchemaMigrations::Context).to have_received(:new).with(connection, database)
    end

    it 'creates migrations with context and calls load_all' do
      described_class.load_all(connection, database)

      expect(ClickHouse::SchemaMigrations::Migrations).to have_received(:new).with(context)
      expect(migrations).to have_received(:load_all)
    end
  end
end

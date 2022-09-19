# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DisableJoins' do
  let(:primary_model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_primary_records'

      def self.name
        'TestPrimary'
      end
    end
  end

  let(:bridge_model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_bridge_records'

      def self.name
        'TestBridge'
      end
    end
  end

  let(:secondary_model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_secondary_records'

      def self.name
        'TestSecondary'
      end
    end
  end

  context 'passing disable_joins as an association option' do
    context 'when the association is a bare has_one' do
      it 'disallows the disable_joins option' do
        expect do
          primary_model.has_one :test_bridge, disable_joins: true
        end.to raise_error(ArgumentError, /Unknown key: :disable_joins/)
      end
    end

    context 'when the association is a belongs_to' do
      it 'disallows the disable_joins option' do
        expect do
          bridge_model.belongs_to :test_secondary, disable_joins: true
        end.to raise_error(ArgumentError, /Unknown key: :disable_joins/)
      end
    end

    context 'when the association is has_one :through' do
      it 'allows the disable_joins option' do
        primary_model.has_one :test_bridge
        bridge_model.belongs_to :test_secondary

        expect do
          primary_model.has_one :test_secondary, through: :test_bridge, disable_joins: true
        end.not_to raise_error
      end
    end

    context 'when the association is a bare has_many' do
      it 'disallows the disable_joins option' do
        expect do
          primary_model.has_many :test_bridges, disable_joins: true
        end.to raise_error(ArgumentError, /Unknown key: :disable_joins/)
      end
    end

    context 'when the association is a has_many :through' do
      it 'allows the disable_joins option' do
        primary_model.has_many :test_bridges
        bridge_model.belongs_to :test_secondary

        expect do
          primary_model.has_many :test_secondaries, through: :test_bridges, disable_joins: true
        end.not_to raise_error
      end
    end
  end

  context 'querying has_one :through when disable_joins is set' do
    before do
      create_tables(<<~SQL)
        CREATE TABLE _test_primary_records (
          id serial NOT NULL PRIMARY KEY);

        CREATE TABLE _test_bridge_records (
          id serial NOT NULL PRIMARY KEY,
          primary_record_id int NOT NULL,
          secondary_record_id int NOT NULL);

        CREATE TABLE _test_secondary_records (
          id serial NOT NULL PRIMARY KEY);
      SQL

      primary_model.has_one :test_bridge, anonymous_class: bridge_model, foreign_key: :primary_record_id
      bridge_model.belongs_to :test_secondary, anonymous_class: secondary_model, foreign_key: :secondary_record_id
      primary_model.has_one :test_secondary,
        through: :test_bridge, anonymous_class: secondary_model, disable_joins: -> { joins_disabled_flag }

      primary_record = primary_model.create!
      secondary_record = secondary_model.create!
      bridge_model.create!(primary_record_id: primary_record.id, secondary_record_id: secondary_record.id)
    end

    context 'when disable_joins evaluates to true' do
      let(:joins_disabled_flag) { true }

      it 'executes separate queries' do
        primary_record = primary_model.first

        query_count = ActiveRecord::QueryRecorder.new { primary_record.test_secondary }.count

        expect(query_count).to eq(2)
      end
    end

    context 'when disable_joins evalutes to false' do
      let(:joins_disabled_flag) { false }

      it 'executes a single query' do
        primary_record = primary_model.first

        query_count = ActiveRecord::QueryRecorder.new { primary_record.test_secondary }.count

        expect(query_count).to eq(1)
      end
    end
  end

  context 'querying has_many :through when disable_joins is set' do
    before do
      create_tables(<<~SQL)
        CREATE TABLE _test_primary_records (
          id serial NOT NULL PRIMARY KEY);

        CREATE TABLE _test_bridge_records (
          id serial NOT NULL PRIMARY KEY,
          primary_record_id int NOT NULL);

        CREATE TABLE _test_secondary_records (
          id serial NOT NULL PRIMARY KEY,
          bridge_record_id int NOT NULL);
      SQL

      primary_model.has_many :test_bridges, anonymous_class: bridge_model, foreign_key: :primary_record_id
      bridge_model.has_many :test_secondaries, anonymous_class: secondary_model, foreign_key: :bridge_record_id
      primary_model.has_many :test_secondaries, through: :test_bridges, anonymous_class: secondary_model,
                                                disable_joins: -> { disabled_join_flag }

      primary_record = primary_model.create!
      bridge_record = bridge_model.create!(primary_record_id: primary_record.id)
      secondary_model.create!(bridge_record_id: bridge_record.id)
    end

    context 'when disable_joins evaluates to true' do
      let(:disabled_join_flag) { true }

      it 'executes separate queries' do
        primary_record = primary_model.first

        query_count = ActiveRecord::QueryRecorder.new { primary_record.test_secondaries.first }.count

        expect(query_count).to eq(2)
      end
    end

    context 'when disable_joins evalutes to false' do
      let(:disabled_join_flag) { false }

      it 'executes a single query' do
        primary_record = primary_model.first

        query_count = ActiveRecord::QueryRecorder.new { primary_record.test_secondaries.first }.count

        expect(query_count).to eq(1)
      end
    end
  end

  context 'querying STI relationships' do
    let(:child_bridge_model) do
      Class.new(bridge_model) do
        def self.name
          'ChildBridge'
        end
      end
    end

    let(:child_secondary_model) do
      Class.new(secondary_model) do
        def self.name
          'ChildSecondary'
        end
      end
    end

    before do
      create_tables(<<~SQL)
        CREATE TABLE _test_primary_records (
          id serial NOT NULL PRIMARY KEY);

        CREATE TABLE _test_bridge_records (
          id serial NOT NULL PRIMARY KEY,
          primary_record_id int NOT NULL,
          type text);

        CREATE TABLE _test_secondary_records (
          id serial NOT NULL PRIMARY KEY,
          bridge_record_id int NOT NULL,
          type text);
      SQL

      primary_model.has_many :child_bridges, anonymous_class: child_bridge_model, foreign_key: :primary_record_id
      child_bridge_model.has_one :child_secondary, anonymous_class: child_secondary_model, foreign_key: :bridge_record_id
      primary_model.has_many :child_secondaries, through: :child_bridges, anonymous_class: child_secondary_model, disable_joins: true

      primary_record = primary_model.create!
      parent_bridge_record = bridge_model.create!(primary_record_id: primary_record.id)
      child_bridge_record = child_bridge_model.create!(primary_record_id: primary_record.id)

      secondary_model.create!(bridge_record_id: child_bridge_record.id)
      child_secondary_model.create!(bridge_record_id: parent_bridge_record.id)
      child_secondary_model.create!(bridge_record_id: child_bridge_record.id)
    end

    it 'filters correctly by the STI type across multiple queries' do
      primary_record = primary_model.first

      query_recorder = ActiveRecord::QueryRecorder.new do
        expect(primary_record.child_secondaries.count).to eq(1)
      end

      expect(query_recorder.count).to eq(2)
    end
  end

  context 'querying polymorphic relationships' do
    before do
      create_tables(<<~SQL)
        CREATE TABLE _test_primary_records (
          id serial NOT NULL PRIMARY KEY);

        CREATE TABLE _test_bridge_records (
          id serial NOT NULL PRIMARY KEY,
          primaryable_id int NOT NULL,
          primaryable_type text NOT NULL);

        CREATE TABLE _test_secondary_records (
          id serial NOT NULL PRIMARY KEY,
          bridgeable_id int NOT NULL,
          bridgeable_type text NOT NULL);
      SQL

      primary_model.has_many :test_bridges, anonymous_class: bridge_model, foreign_key: :primaryable_id, as: :primaryable
      bridge_model.has_one :test_secondaries, anonymous_class: secondary_model, foreign_key: :bridgeable_id, as: :bridgeable
      primary_model.has_many :test_secondaries, through: :test_bridges, anonymous_class: secondary_model, disable_joins: true

      primary_record = primary_model.create!
      primary_bridge_record = bridge_model.create!(primaryable_id: primary_record.id, primaryable_type: 'TestPrimary')
      nonprimary_bridge_record = bridge_model.create!(primaryable_id: primary_record.id, primaryable_type: 'NonPrimary')

      secondary_model.create!(bridgeable_id: primary_bridge_record.id, bridgeable_type: 'TestBridge')
      secondary_model.create!(bridgeable_id: nonprimary_bridge_record.id, bridgeable_type: 'TestBridge')
      secondary_model.create!(bridgeable_id: primary_bridge_record.id, bridgeable_type: 'NonBridge')
    end

    it 'filters correctly by the polymorphic type across multiple queries' do
      primary_record = primary_model.first

      query_recorder = ActiveRecord::QueryRecorder.new do
        expect(primary_record.test_secondaries.count).to eq(1)
      end

      expect(query_recorder.count).to eq(2)
    end
  end

  def create_tables(table_sql)
    ApplicationRecord.connection.execute(table_sql)

    bridge_model.reset_column_information
    secondary_model.reset_column_information
  end
end

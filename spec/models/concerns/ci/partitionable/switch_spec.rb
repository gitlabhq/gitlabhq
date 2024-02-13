# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable::Switch, :aggregate_failures, feature_category: :continuous_integration do
  let(:model) do
    Class.new(Ci::ApplicationRecord) do
      self.primary_key = :id
      self.table_name = :_test_ci_jobs_metadata
      self.sequence_name = :_test_ci_jobs_metadata_id_seq

      def self.name
        'TestSwitchJobMetadata'
      end
    end
  end

  let(:table_rollout_flag) { :ci_partitioning_use_test_routing_table }

  let(:partitioned_model) { model::Partitioned }

  let(:jobs_model) do
    Class.new(Ci::ApplicationRecord) do
      self.primary_key = :id
      self.table_name = :_test_ci_jobs

      def self.name
        'TestSwitchJob'
      end
    end
  end

  before do
    create_tables(<<~SQL)
      CREATE TABLE _test_ci_jobs_metadata(
        id serial NOT NULL PRIMARY KEY,
        job_id int,
        partition_id int NOT NULL DEFAULT 1,
        type text,
        expanded_environment_name text);

      CREATE TABLE _test_p_ci_jobs_metadata (
        LIKE _test_ci_jobs_metadata INCLUDING DEFAULTS
      ) PARTITION BY LIST(partition_id);

      ALTER TABLE _test_p_ci_jobs_metadata
        ADD CONSTRAINT _test_p_ci_jobs_metadata_id_partition_id
        UNIQUE (id, partition_id);

      ALTER TABLE _test_p_ci_jobs_metadata
        ATTACH PARTITION _test_ci_jobs_metadata FOR VALUES IN (1);

      CREATE TABLE _test_ci_jobs(id serial NOT NULL PRIMARY KEY);
    SQL

    stub_const('Ci::Partitionable::Testing::PARTITIONABLE_MODELS', [model.name])

    model.include(Ci::Partitionable)

    model.partitionable scope: ->(r) { 1 },
      through: { table: :_test_p_ci_jobs_metadata, flag: table_rollout_flag }

    model.belongs_to :job, anonymous_class: jobs_model

    jobs_model.has_one :metadata,
      anonymous_class: model,
      foreign_key: :job_id, inverse_of: :job,
      dependent: :destroy

    allow(Feature::Definition).to receive(:get).and_call_original
    allow(Feature::Definition).to receive(:get).with(table_rollout_flag)
      .and_return(
        Feature::Definition.new("development/#{table_rollout_flag}.yml",
          { type: 'gitlab_com_derisk', name: table_rollout_flag }
        )
      )
  end

  # the models defined here are leaked to other tests through
  # `ActiveRecord::Base.descendants` and we need to counter the side effects
  # from this. We redefine the method so that we don't check the FF existence
  # outside of the examples here.
  # `ActiveSupport::DescendantsTracker.clear` doesn't work with cached classes.
  after do
    model.define_singleton_method(:routing_table_enabled?) { false }
  end

  it { expect(model).not_to be_routing_class }

  it { expect(partitioned_model).to be_routing_class }

  it { expect(partitioned_model.table_name).to eq('_test_p_ci_jobs_metadata') }

  it { expect(partitioned_model.quoted_table_name).to eq('"_test_p_ci_jobs_metadata"') }

  it { expect(partitioned_model.arel_table.name).to eq('_test_p_ci_jobs_metadata') }

  it { expect(partitioned_model.sequence_name).to eq('_test_ci_jobs_metadata_id_seq') }

  context 'when switching the tables' do
    before do
      stub_feature_flags(table_rollout_flag => false)
    end

    %i[table_name quoted_table_name arel_table predicate_builder].each do |name|
      it "switches #{name} to routing table and rollbacks" do
        old_value = model.public_send(name)
        routing_value = partitioned_model.public_send(name)

        expect(old_value).not_to eq(routing_value)

        expect { stub_feature_flags(table_rollout_flag => true) }
          .to change(model, name).from(old_value).to(routing_value)

        expect { stub_feature_flags(table_rollout_flag => false) }
          .to change(model, name).from(routing_value).to(old_value)
      end
    end

    it 'can switch aggregate methods' do
      rollout_and_rollback_flag(
        -> { expect(sql { model.count }).to all match(/FROM "_test_ci_jobs_metadata"/) },
        -> { expect(sql { model.count }).to all match(/FROM "_test_p_ci_jobs_metadata"/) }
      )
    end

    it 'can switch reads' do
      rollout_and_rollback_flag(
        -> { expect(sql { model.last }).to all match(/FROM "_test_ci_jobs_metadata"/) },
        -> { expect(sql { model.last }).to all match(/FROM "_test_p_ci_jobs_metadata"/) }
      )
    end

    it 'can switch inserts' do
      rollout_and_rollback_flag(
        -> {
          expect(sql(filter: /INSERT/) { model.create! })
            .to all match(/INSERT INTO "_test_ci_jobs_metadata"/)
        },
        -> {
          expect(sql(filter: /INSERT/) { model.create! })
            .to all match(/INSERT INTO "_test_p_ci_jobs_metadata"/)
        }
      )
    end

    it 'can switch deletes' do
      3.times { model.create! }

      rollout_and_rollback_flag(
        -> {
          expect(sql(filter: /DELETE/) { model.last.destroy! })
            .to all match(/DELETE FROM "_test_ci_jobs_metadata"/)
        },
        -> {
          expect(sql(filter: /DELETE/) { model.last.destroy! })
            .to all match(/DELETE FROM "_test_p_ci_jobs_metadata"/)
        }
      )
    end

    context 'with associations' do
      let(:job) { jobs_model.create! }

      it 'reads' do
        model.create!(job_id: job.id)

        rollout_and_rollback_flag(
          -> {
            expect(sql(filter: /jobs_metadata/) { jobs_model.find(job.id).metadata })
              .to all match(/FROM "_test_ci_jobs_metadata"/)
          },
          -> {
            expect(sql(filter: /jobs_metadata/) { jobs_model.find(job.id).metadata })
              .to all match(/FROM "_test_p_ci_jobs_metadata"/)
          }
        )
      end

      it 'writes' do
        rollout_and_rollback_flag(
          -> {
            expect(sql(filter: [/INSERT/, /jobs_metadata/]) { jobs_model.find(job.id).create_metadata! })
              .to all match(/INSERT INTO "_test_ci_jobs_metadata"/)
          },
          -> {
            expect(sql(filter: [/INSERT/, /jobs_metadata/]) { jobs_model.find(job.id).create_metadata! })
              .to all match(/INSERT INTO "_test_p_ci_jobs_metadata"/)
          }
        )
      end

      it 'deletes' do
        3.times do
          job = jobs_model.create!
          job.create_metadata!
        end

        rollout_and_rollback_flag(
          -> {
            expect(sql(filter: [/DELETE/, /jobs_metadata/]) { jobs_model.last.destroy! })
              .to all match(/DELETE FROM "_test_ci_jobs_metadata"/)
          },
          -> {
            expect(sql(filter: [/DELETE/, /jobs_metadata/]) { jobs_model.last.destroy! })
              .to all match(/DELETE FROM "_test_p_ci_jobs_metadata"/)
          }
        )
      end

      it 'can switch joins from jobs' do
        rollout_and_rollback_flag(
          -> {
            expect(sql { jobs_model.joins(:metadata).last })
              .to all match(/INNER JOIN "_test_ci_jobs_metadata"/)
          },
          -> {
            expect(sql { jobs_model.joins(:metadata).last })
              .to all match(/INNER JOIN "_test_p_ci_jobs_metadata"/)
          }
        )
      end

      it 'can switch joins from metadata' do
        rollout_and_rollback_flag(
          -> {
            expect(sql { model.joins(:job).last })
              .to all match(/FROM "_test_ci_jobs_metadata" INNER JOIN "_test_ci_jobs"/)
          },
          -> {
            expect(sql { model.joins(:job).last })
              .to all match(/FROM "_test_p_ci_jobs_metadata" INNER JOIN "_test_ci_jobs"/)
          }
        )
      end

      it 'preloads' do
        job = jobs_model.create!
        job.create_metadata!

        rollout_and_rollback_flag(
          -> {
            expect(sql(filter: /jobs_metadata/) { jobs_model.preload(:metadata).last })
              .to all match(/FROM "_test_ci_jobs_metadata"/)
          },
          -> {
            expect(sql(filter: /jobs_metadata/) { jobs_model.preload(:metadata).last })
              .to all match(/FROM "_test_p_ci_jobs_metadata"/)
          }
        )
      end

      context 'with nested attributes' do
        before do
          jobs_model.accepts_nested_attributes_for :metadata
        end

        it 'writes' do
          attrs = { metadata_attributes: { expanded_environment_name: 'test_env_name' } }

          rollout_and_rollback_flag(
            -> {
              expect(sql(filter: [/INSERT/, /jobs_metadata/]) { jobs_model.create!(attrs) })
                .to all match(/INSERT INTO "_test_ci_jobs_metadata" .* 'test_env_name'/)
            },
            -> {
              expect(sql(filter: [/INSERT/, /jobs_metadata/]) { jobs_model.create!(attrs) })
                .to all match(/INSERT INTO "_test_p_ci_jobs_metadata" .* 'test_env_name'/)
            }
          )
        end
      end
    end
  end

  context 'with safe request store', :request_store do
    it 'changing the flag to true does not affect the current request' do
      stub_feature_flags(table_rollout_flag => false)

      expect(model.table_name).to eq('_test_ci_jobs_metadata')

      stub_feature_flags(table_rollout_flag => true)

      expect(model.table_name).to eq('_test_ci_jobs_metadata')
    end

    it 'changing the flag to false does not affect the current request' do
      stub_feature_flags(table_rollout_flag => true)

      expect(model.table_name).to eq('_test_p_ci_jobs_metadata')

      stub_feature_flags(table_rollout_flag => false)

      expect(model.table_name).to eq('_test_p_ci_jobs_metadata')
    end
  end

  def rollout_and_rollback_flag(old, new)
    # Load class and SQL statements cache
    old.call

    stub_feature_flags(table_rollout_flag => true)

    # Test switch
    new.call

    stub_feature_flags(table_rollout_flag => false)

    # Test that it can switch back in the same process
    old.call
  end

  def create_tables(table_sql)
    Ci::ApplicationRecord.connection.execute(table_sql)
  end

  def sql(filter: nil, &block)
    ActiveRecord::QueryRecorder.new(&block)
      .log
      .select { |statement| Array.wrap(filter).all? { |regex| statement.match?(regex) } }
      .tap { |result| expect(result).not_to be_empty }
  end
end

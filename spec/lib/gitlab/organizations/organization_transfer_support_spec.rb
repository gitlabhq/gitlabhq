# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'organization transfer support tracking', :aggregate_failures, feature_category: :organization do
  let(:valid_statuses) { Gitlab::Organizations::TransferSupportRegistry::VALID_STATUSES }

  let(:org_sharded_tables) do
    Gitlab::Database::Dictionary.entries.select do |entry|
      sharded_by_organization?(entry)
    end
  end

  describe 'registry file' do
    let(:registry) { Gitlab::Organizations::TransferSupportRegistry.registry }

    it 'contains only valid status values' do
      registry.each do |table_name, status|
        expect(status).to be_in(valid_statuses),
          "Table '#{table_name}' has invalid organization_transfer_support value '#{status}' " \
            "in config/organizations/transfer_support.yml. " \
            "Must be one of: #{valid_statuses.join(', ')}"
      end
    end

    it 'contains only active tables that exist in the database dictionary' do
      registry.each_key do |table_name|
        entry = Gitlab::Database::Dictionary.entry(table_name)

        expect(entry).to be_present,
          "Table '#{table_name}' is in config/organizations/transfer_support.yml " \
            "but doesn't exist in the database dictionary (or is a deleted table). " \
            "Remove it from the registry."
      end
    end

    it 'contains only organization-sharded tables' do
      registry.each_key do |table_name|
        entry = Gitlab::Database::Dictionary.entry(table_name)
        next unless entry # existence checked separately

        expect(sharded_by_organization?(entry)).to be(true),
          "Table '#{table_name}' is in config/organizations/transfer_support.yml " \
            "but is not sharded by organization (sharding_key: #{entry.sharding_key}). " \
            "Only organization-sharded tables belong in this registry."
      end
    end

    it 'is sorted alphabetically' do
      table_names = registry.keys
      expect(table_names).to eq(table_names.sort),
        "Tables in config/organizations/transfer_support.yml must be sorted alphabetically."
    end
  end

  describe 'tables sharded by organization_id' do
    it 'requires an entry in the transfer support registry for all tables sharded by organization_id' do
      org_sharded_tables.each do |entry|
        transfer_support = entry.organization_transfer_support

        expect(transfer_support).to be_present,
          "Table '#{entry.table_name}' is sharded by organization_id but missing " \
            "from config/organizations/transfer_support.yml. " \
            "Add an entry with the appropriate status."
      end
    end

    it 'requires a valid status value' do
      org_sharded_tables.each do |entry|
        transfer_support = entry.organization_transfer_support
        next unless transfer_support

        expect(transfer_support).to be_in(valid_statuses),
          "Table '#{entry.table_name}' has invalid organization_transfer_support value '#{transfer_support}'. " \
            "Must be one of: #{valid_statuses.join(', ')}"
      end
    end
  end

  def sharded_by_organization?(entry)
    # skip 'organizations' table because we're not transferring any data from it
    return unless entry.table_name != "organizations"
    return unless entry.sharding_key.is_a?(Hash)

    entry.sharding_key.invert["organizations"].present?
  end

  # These tests validate that:
  # 1. Tables marked 'supported' in config/organizations/transfer_support.yml are actually updated during transfer specs
  # 2. Tables updated during transfer specs are marked 'supported' in config/organizations/transfer_support.yml
  #
  # The transfer specs are loaded and run internally before validation.
  #
  # We can only run these specs in EE as this will cover FOSS & EE models. Running this spec in
  # FOSS_ONLY=1 <run_spec> leads to specs failing because the models don't exist in FOSS but
  # we've marked them as supported. (e.g db/docs/vulnerability_exports.yml)
  # rubocop:disable RSpec/InstanceVariable -- We need to track sql queries around all the specs
  describe 'runtime transfer tracking validation', :eager_load, if: Gitlab.ee? do
    before(:context) do
      @tracker = Gitlab::Organizations::TransferTracker.new(
        service_path_pattern: %r{app/services/.*#{transfer_path_pattern}}o
      )
      @tracker.track do
        load_and_run_transfer_specs
      end
    end

    let(:supported_tables) do
      org_sharded_tables.select do |entry|
        entry.organization_transfer_support == 'supported'
      end
    end

    it 'ensures tables marked supported were actually updated during transfer specs' do
      supported_tables.each do |entry|
        expect(@tracker.tracked_tables).to include(entry.table_name),
          "Table '#{entry.table_name}' has organization_transfer_support: supported " \
            "in config/organizations/transfer_support.yml but was not updated during any transfer spec. " \
            "Either add test coverage, update the status to 'todo' if transfer support is " \
            "not yet implemented, or 'no_work_needed' if no transfer work is required."
      end
    end

    it 'ensures tables updated during transfer are marked as supported' do
      @tracker.tracked_table_locations.each do |table_name, locations|
        entry = Gitlab::Database::Dictionary.entry(table_name)

        locations_text = locations.to_a.sort.map { |loc| "  - #{loc}" }.join("\n")

        expect(entry.organization_transfer_support).to eq('supported'),
          "Table '#{table_name}' was updated during transfer at:\n" \
            "#{locations_text}\n" \
            "but has organization_transfer_support: '#{entry.organization_transfer_support}' " \
            "in config/organizations/transfer_support.yml. Update it to 'supported'."
      end
    end
    # rubocop:enable RSpec/InstanceVariable

    def transfer_path_pattern
      'organizations/transfer/'
    end

    def load_and_run_transfer_specs
      spec_files = transfer_spec_files

      raise ArgumentError, "Expected transfer specs at **/#{transfer_path_pattern} but found none" if spec_files.empty?

      spec_files.each { |file| require file }

      reporter = RSpec::Core::NullReporter

      transfer_group_examples(spec_files).each do |group|
        group.run(reporter)
      end
    end

    def transfer_spec_files
      Dir.glob(Rails.root.join("{,ee/}spec/services/**/#{transfer_path_pattern}**/*_spec.rb"))
        .reject { |f| f.include?('/concerns/') }
    end

    # Called after specs are required so that they're visible in Rspec.world
    def transfer_group_examples(spec_files)
      RSpec.world.example_groups.select do |group|
        spec_files.include?(group.metadata[:absolute_file_path])
      end
    end
  end
end

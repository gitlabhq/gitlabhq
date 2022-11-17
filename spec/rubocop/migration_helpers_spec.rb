# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../rubocop/migration_helpers'

RSpec.describe RuboCop::MigrationHelpers do
  using RSpec::Parameterized::TableSyntax

  subject(:fake_cop) { Class.new { include RuboCop::MigrationHelpers }.new }

  let(:node) { double(:node) }

  before do
    allow(node).to receive_message_chain('location.expression.source_buffer.name')
                     .and_return(name)
  end

  describe '#in_migration?' do
    where(:name, :expected) do
      '/gitlab/db/migrate/20200210184420_create_operations_scopes_table.rb'          | true
      '/gitlab/db/post_migrate/20200210184420_create_operations_scopes_table.rb'     | true
      '/gitlab/db/geo/migrate/20200210184420_create_operations_scopes_table.rb'      | true
      '/gitlab/db/geo/post_migrate/20200210184420_create_operations_scopes_table.rb' | true
      '/gitlab/db/elsewhere/20200210184420_create_operations_scopes_table.rb'        | false
    end

    with_them do
      it { expect(fake_cop.in_migration?(node)).to eq(expected) }
    end
  end

  describe '#in_post_deployment_migration?' do
    where(:name, :expected) do
      '/gitlab/db/migrate/20200210184420_create_operations_scopes_table.rb'          | false
      '/gitlab/db/post_migrate/20200210184420_create_operations_scopes_table.rb'     | true
      '/gitlab/db/geo/migrate/20200210184420_create_operations_scopes_table.rb'      | false
      '/gitlab/db/geo/post_migrate/20200210184420_create_operations_scopes_table.rb' | true
      '/gitlab/db/elsewhere/20200210184420_create_operations_scopes_table.rb'        | false
    end

    with_them do
      it { expect(fake_cop.in_post_deployment_migration?(node)).to eq(expected) }
    end
  end

  describe "#version" do
    let(:name) do
      '/path/to/gitlab/db/migrate/20200210184420_create_operations_scopes_table.rb'
    end

    it { expect(fake_cop.version(node)).to eq(20200210184420) }
  end

  describe '#time_enforced?' do
    before do
      allow(fake_cop).to receive(:name).and_return("TestCop")
      allow(fake_cop).to receive(:config).and_return(double(for_cop: { 'EnforcedSince' => 20221018000000 }))
    end

    where(:name, :expected) do
      '/gitlab/db/post_migrate/20200210184420_create_operations_scopes_table.rb' | false
      '/gitlab/db/post_migrate/20220210184420_create_fake_table.rb'              | false
      '/gitlab/db/post_migrate/20221019184420_add_id_to_reports_table.rb'        | true
    end

    with_them do
      it { expect(fake_cop.time_enforced?(node)).to eq(expected) }
    end
  end
end

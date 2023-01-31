# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PostgreSQL registered types' do
  subject(:types) { ApplicationRecord.connection.reload_type_map.keys }

  # These can be obtained via SELECT oid, typname from pg_type
  it 'includes custom and standard OIDs' do
    expect(types).to include(28, 194, 1034, 3220, 23, 20)
  end

  it 'includes custom and standard types' do
    expect(types).to include('xid', 'pg_node_tree', '_aclitem', 'pg_lsn', 'int4', 'int8')
  end
end

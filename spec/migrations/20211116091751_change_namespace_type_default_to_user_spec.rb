# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ChangeNamespaceTypeDefaultToUser do
  let(:namespaces) { table(:namespaces) }

  it 'defaults type to User' do
    some_namespace1 = namespaces.create!(name: 'magic namespace1', path: 'magicnamespace1', type: nil)

    expect(some_namespace1.reload.type).to be_nil

    migrate!

    some_namespace2 = namespaces.create!(name: 'magic namespace2', path: 'magicnamespace2', type: nil)

    expect(some_namespace1.reload.type).to be_nil
    expect(some_namespace2.reload.type).to eq 'User'
  end
end

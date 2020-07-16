# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceSettings, schema: 20200703125016 do
  let(:namespaces) { table(:namespaces) }
  let(:namespace_settings) { table(:namespace_settings) }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }

  subject { described_class.new }

  describe '#perform' do
    it 'creates settings for all projects in range' do
      namespaces.create!(id: 5, name: 'test1', path: 'test1')
      namespaces.create!(id: 7, name: 'test2', path: 'test2')
      namespaces.create!(id: 8, name: 'test3', path: 'test3')

      subject.perform(5, 7)

      expect(namespace_settings.all.pluck(:namespace_id)).to contain_exactly(5, 7)
    end
  end
end

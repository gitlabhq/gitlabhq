# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveEmptyGithubServiceTemplates do
  subject(:migration) { described_class.new }

  let(:services) do
    table(:services).tap do |klass|
      klass.class_eval do
        serialize :properties, JSON
      end
    end
  end

  before do
    services.delete_all

    create_service(properties: nil)
    create_service(properties: {})
    create_service(properties: { some: :value })
    create_service(properties: {}, template: false)
    create_service(properties: {}, type: 'SomeType')
  end

  def all_service_properties
    services.where(template: true, type: 'GithubService').pluck(:properties)
  end

  it 'correctly migrates up and down service templates' do
    reversible_migration do |migration|
      migration.before -> do
        expect(services.count).to eq(5)

        expect(all_service_properties)
          .to match(a_collection_containing_exactly(nil, {}, { 'some' => 'value' }))
      end

      migration.after -> do
        expect(services.count).to eq(4)

        expect(all_service_properties)
          .to match(a_collection_containing_exactly(nil, { 'some' => 'value' }))
      end
    end
  end

  def create_service(params)
    data = { template: true, type: 'GithubService' }
    data.merge!(params)

    services.create!(data)
  end
end

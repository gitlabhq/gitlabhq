# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::TablesWithDestroyServices, feature_category: :database do
  let(:root) { Pathname.new(Dir.mktmpdir) }

  def add_service(path)
    FileUtils.mkdir_p(root.join(File.dirname(path)))
    FileUtils.touch(root.join(path))
  end

  def add_table_doc(table)
    FileUtils.mkdir_p(root.join('db/docs'))
    FileUtils.touch(root.join("db/docs/#{table}.yml"))
  end

  def reset_memoized_scan
    described_class.instance_variable_set(:@tables_to_services, nil)
    described_class.instance_variable_set(:@unaccounted_namespaces, nil)
  end

  before do
    allow(described_class).to receive(:root_path).and_return(root.to_s)
    reset_memoized_scan
  end

  after do
    FileUtils.rm_rf(root)
    reset_memoized_scan
  end

  describe '.tables_to_services' do
    subject(:tables_to_services) { described_class.tables_to_services }

    it 'maps deletion services in app/services and ee/app/services to their table' do
      add_service('app/services/widgets/destroy_service.rb')
      add_service('ee/app/services/gadgets/delete_service.rb')
      add_table_doc('widgets')
      add_table_doc('gadgets')

      expect(tables_to_services).to include(
        'widgets' => ['Widgets::DestroyService'],
        'gadgets' => ['Gadgets::DeleteService']
      )
    end

    it 'maps deletion services in CE domains to their table' do
      add_service('domains/widgets/app/services/widgets/destroy_service.rb')
      add_table_doc('widgets')

      expect(tables_to_services['widgets']).to eq(['Widgets::DestroyService'])
    end

    it 'maps deletion services in EE domains to their table' do
      add_service('domains/cd/ee/app/services/cd/application_links/delete_service.rb')
      add_table_doc('cd_application_links')

      expect(tables_to_services['cd_application_links']).to eq(['Cd::ApplicationLinks::DeleteService'])
    end
  end

  describe '.unaccounted_namespaces' do
    it 'reports a domain service whose table is not documented' do
      add_service('domains/widgets/app/services/widgets/destroy_service.rb')

      expect(described_class.unaccounted_namespaces).to eq(['widgets'])
    end
  end
end

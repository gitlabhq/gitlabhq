# frozen_string_literal: true

RSpec.shared_examples 'installable packages' do |factory_name|
  context "for #{factory_name}", :aggregate_failures do
    let_it_be(:default_package) { create(factory_name, :default) }
    let_it_be(:hidden_package) { create(factory_name, :hidden) }
    let_it_be(:processing_package) { create(factory_name, :processing) }
    let_it_be(:error_package) { create(factory_name, :error) }
    let_it_be(:deprecated_package) { create(factory_name, :deprecated) }

    subject { described_class.installable }

    it 'does not include non-installable packages' do
      is_expected.not_to include(error_package)
      is_expected.not_to include(processing_package)
    end

    it 'includes installable packages' do
      is_expected.to include(default_package)
      is_expected.to include(hidden_package)
      is_expected.to include(deprecated_package)
    end
  end
end

RSpec.shared_examples 'installable statuses' do
  it 'returns installable statuses' do
    expect(described_class.installable_statuses).to eq(described_class::INSTALLABLE_STATUSES)
  end
end

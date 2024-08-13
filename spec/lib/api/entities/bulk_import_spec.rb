# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImport, feature_category: :importers do
  let_it_be(:import) { create(:bulk_import, :with_configuration) }

  subject { described_class.new(import).as_json }

  it 'has the correct attributes' do
    expect(subject).to include(
      :id,
      :status,
      :source_type,
      :source_url,
      :created_at,
      :updated_at,
      :has_failures
    )
  end

  it 'exposes source url via configuration' do
    expected_url = import.configuration.url

    expect(subject[:source_url]).to eq(expected_url)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImport do
  let_it_be(:import) { create(:bulk_import) }

  subject { described_class.new(import).as_json }

  it 'has the correct attributes' do
    expect(subject).to include(
      :id,
      :status,
      :source_type,
      :created_at,
      :updated_at
    )
  end
end

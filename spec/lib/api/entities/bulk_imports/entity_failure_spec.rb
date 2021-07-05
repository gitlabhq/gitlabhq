# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImports::EntityFailure do
  let_it_be(:failure) { create(:bulk_import_failure) }

  subject { described_class.new(failure).as_json }

  it 'has the correct attributes' do
    expect(subject).to include(
      :pipeline_class,
      :pipeline_step,
      :exception_class,
      :correlation_id_value,
      :created_at
    )
  end
end

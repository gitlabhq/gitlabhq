# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImports::EntityFailure do
  let_it_be(:failure) { create(:bulk_import_failure) }

  subject { described_class.new(failure).as_json }

  it 'has the correct attributes' do
    expect(subject).to include(
      :relation,
      :step,
      :exception_class,
      :exception_message,
      :correlation_id_value,
      :created_at
    )
  end

  describe 'exception message' do
    it 'truncates exception message to 72 characters' do
      failure.update!(exception_message: 'a' * 100)

      expect(subject[:exception_message].length).to eq(72)
    end

    it 'removes paths from the message' do
      failure.update!(exception_message: 'Test /foo/bar')

      expect(subject[:exception_message]).to eq('Test [FILTERED]')
    end
  end
end

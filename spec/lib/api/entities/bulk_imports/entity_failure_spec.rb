# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BulkImports::EntityFailure, feature_category: :importers do
  let_it_be(:failure) { create(:bulk_import_failure) }

  subject { described_class.new(failure).as_json }

  it 'has the correct attributes' do
    expect(subject).to include(
      :relation,
      :exception_message,
      :exception_class,
      :correlation_id_value,
      :source_url,
      :source_title
    )
  end

  describe 'exception message' do
    it 'truncates exception message to 255 characters' do
      failure.update!(exception_message: 'a' * 500)

      expect(subject[:exception_message].length).to eq(255)
    end

    it 'removes paths from the message' do
      failure.update!(exception_message: 'Test /foo/bar')

      expect(subject[:exception_message]).to eq('Test [FILTERED]')
    end

    it 'removes long paths without clipping the message' do
      exception_message = "Test #{'/abc' * 300} #{'a' * 500}"
      failure.update!(exception_message: exception_message)
      filtered_message = "Test [FILTERED] #{'a' * 500}"

      expect(subject[:exception_message]).to eq(filtered_message.truncate(255))
    end
  end

  describe 'relation' do
    it 'returns relation' do
      expect(subject[:relation]).to eq('test')
    end

    context 'when subrelation is present' do
      it 'includes subrelation' do
        failure.update!(subrelation: 'subrelation')

        expect(subject[:relation]).to eq('test, subrelation')
      end
    end
  end
end

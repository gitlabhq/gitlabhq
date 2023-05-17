# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImportEntity, feature_category: :importers do
  let(:importable_data) do
    {
      'id' => 1,
      'full_name' => 'test',
      'full_path' => 'full/path/tes',
      'web_url' => 'http://web.url/path',
      'foo' => 'bar'
    }
  end

  subject { described_class.represent(importable_data).as_json }

  %w[id full_name full_path web_url].each do |attribute|
    it "exposes #{attribute}" do
      expect(subject[attribute.to_sym]).to eq(importable_data[attribute])
    end
  end

  it 'does not expose unspecified attributes' do
    expect(subject[:foo]).to be_nil
  end
end

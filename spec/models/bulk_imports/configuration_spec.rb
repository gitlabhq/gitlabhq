# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Configuration, type: :model, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:bulk_import).required }
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:url).is_at_most(255) }
    it { is_expected.to validate_length_of(:access_token).is_at_most(255) }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:access_token) }
  end

  describe '#safe_url' do
    subject { configuration.safe_url }

    let(:configuration) { build(:bulk_import_configuration, url: url) }
    let(:url) { 'http://user:secret@example.com' }

    it 'returns a masked url' do
      is_expected.to eq 'http://*****:*****@example.com'
    end

    context 'when url is not set' do
      let(:url) { nil }

      it { is_expected.to eq '' }
    end

    context 'when url does not include credentials' do
      let(:url) { 'http://example.com' }

      it { is_expected.to eq url }
    end
  end
end

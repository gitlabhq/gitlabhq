# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HostValidator do # rubocop:disable RSpec/FeatureCategory -- undefined
  let(:validator) { described_class.new(attributes: [:tls_host]) }
  let!(:cluster_agent_url_configuration) { build(:cluster_agent_url_configuration) }

  subject(:validate) { validator.validate_each(cluster_agent_url_configuration, :tls_host, value) }

  context 'with empty value' do
    let(:value) { nil }

    it 'adds error to the record' do
      validate

      expect(cluster_agent_url_configuration.errors).not_to be_empty
    end
  end

  context 'with valid host' do
    let(:value) { 'example.com' }

    it 'does not add any error' do
      validate

      expect(cluster_agent_url_configuration.errors).to be_empty
    end
  end

  context 'with invalid host' do
    let(:value) { 'https://example.com' }

    it 'adds error to the record' do
      validate

      expect(cluster_agent_url_configuration.errors).not_to be_empty
    end
  end

  context 'with syntactically invalid host' do
    let(:value) { '}' }

    it 'adds error to the record' do
      validate

      expect(cluster_agent_url_configuration.errors).not_to be_empty
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Serverless::DomainEntity do
  describe '#as_json' do
    let(:domain) { create(:pages_domain, :instance_serverless) }

    subject { described_class.new(domain).as_json }

    it 'has an id' do
      expect(subject[:id]).to eq(domain.id)
    end

    it 'has a domain' do
      expect(subject[:domain]).to eq(domain.domain)
    end
  end
end

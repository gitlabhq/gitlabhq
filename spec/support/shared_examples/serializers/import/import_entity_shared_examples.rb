# frozen_string_literal: true

RSpec.shared_examples 'exposes required fields for import entity' do
  describe 'exposes required fields' do
    it 'correctly exposes id' do
      expect(subject[:id]).to eql(expected_values[:id])
    end

    it 'correctly exposes full name' do
      expect(subject[:full_name]).to eql(expected_values[:full_name])
    end

    it 'correctly exposes sanitized name' do
      expect(subject[:sanitized_name]).to eql(expected_values[:sanitized_name])
    end

    it 'correctly exposes provider link' do
      expect(subject[:provider_link]).to eql(expected_values[:provider_link])
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HasDataFields, feature_category: :integrations do
  let(:url) { 'http://url.com' }
  let(:username) { 'username_one' }
  let(:properties) do
    { url: url, username: username, jira_issue_transition_automatic: false }
  end

  shared_examples 'data fields' do
    describe '#arg' do
      it 'returns the expected values' do
        expect(integration).to have_attributes(properties)
      end
    end

    describe '{arg}_changed?' do
      it 'returns false when the property has not been assigned a new value' do
        integration.username = 'new_username'
        integration.validate
        expect(integration.url_changed?).to be_falsy
      end

      it 'returns true when the property has been assigned a different value' do
        integration.url = "http://example.com"
        integration.validate
        expect(integration.url_changed?).to be_truthy
      end

      it 'returns true when the property has been assigned a different value twice' do
        integration.url = "http://example.com"
        integration.url = "http://example.com"
        integration.validate
        expect(integration.url_changed?).to be_truthy
      end

      it 'returns false when the property has been re-assigned the same value' do
        integration.url = 'http://url.com'
        integration.validate
        expect(integration.url_changed?).to be_falsy
      end
    end

    describe '{arg}_touched?' do
      it 'returns false when the property has not been assigned a new value' do
        integration.username = 'new_username'
        integration.validate
        expect(integration.url_changed?).to be_falsy
      end

      it 'returns true when the property has been assigned a different value' do
        integration.url = "http://example.com"
        integration.validate
        expect(integration.url_changed?).to be_truthy
      end

      it 'returns true when the property has been assigned a different value twice' do
        integration.url = "http://example.com"
        integration.url = "http://example.com"
        integration.validate
        expect(integration.url_changed?).to be_truthy
      end

      it 'returns true when the property has been re-assigned the same value' do
        integration.url = 'http://url.com'
        expect(integration.url_touched?).to be_truthy
      end

      it 'returns false when the property has been re-assigned the same value' do
        integration.url = 'http://url.com'
        integration.validate
        expect(integration.url_changed?).to be_falsy
      end
    end

    describe 'data_fields_present?' do
      it 'returns true from the issue tracker integration' do
        expect(integration.data_fields_present?).to be true
      end
    end
  end

  context 'when data are stored in data_fields' do
    let(:integration) do
      create(:jira_integration, url: url, username: username)
    end

    it_behaves_like 'data fields'

    describe '{arg}_was?' do
      it 'returns nil' do
        integration.url = 'http://example.com'
        integration.validate
        expect(integration.url_was).to be_nil
      end
    end
  end

  context 'when integration and data_fields are not persisted' do
    let(:integration) do
      Integrations::Jira.new
    end

    describe 'data_fields_present?' do
      it 'returns true' do
        expect(integration.data_fields_present?).to be true
      end
    end
  end

  context 'when data are stored in properties' do
    let(:integration) { create(:jira_integration, :without_properties_callback, properties: properties) }

    it_behaves_like 'data fields'

    describe '{arg}_was?' do
      it 'returns nil when the property has not been assigned a new value' do
        integration.username = 'new_username'
        integration.validate

        expect(integration.url_was).to be_nil
      end

      it 'returns initial value when the property has been assigned a different value' do
        integration.url = 'http://example.com'
        integration.validate

        expect(integration.url_was).to eq('http://url.com')
      end

      it 'returns initial value when the property has been re-assigned the same value' do
        integration.url = 'http://url.com'
        integration.validate

        expect(integration.url_was).to eq('http://url.com')
      end
    end
  end

  context 'when data are stored in both properties and data_fields' do
    let(:integration) do
      create(:jira_integration, :without_properties_callback, active: false, properties: properties).tap do |integration|
        create(:jira_tracker_data, properties.merge(integration: integration))
      end
    end

    it_behaves_like 'data fields'

    describe '{arg}_was?' do
      it 'returns nil' do
        integration.url = 'http://example.com'
        integration.validate
        expect(integration.url_was).to be_nil
      end
    end
  end
end

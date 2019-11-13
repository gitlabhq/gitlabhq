# frozen_string_literal: true

require 'spec_helper'

describe DataFields do
  let(:url) { 'http://url.com' }
  let(:username) { 'username_one' }
  let(:properties) do
    { url: url, username: username }
  end

  shared_examples 'data fields' do
    describe '#arg' do
      it 'returns an argument correctly' do
        expect(service.url).to eq(url)
      end
    end

    describe '{arg}_changed?' do
      it 'returns false when the property has not been assigned a new value' do
        service.username = 'new_username'
        service.validate
        expect(service.url_changed?).to be_falsy
      end

      it 'returns true when the property has been assigned a different value' do
        service.url = "http://example.com"
        service.validate
        expect(service.url_changed?).to be_truthy
      end

      it 'returns true when the property has been assigned a different value twice' do
        service.url = "http://example.com"
        service.url = "http://example.com"
        service.validate
        expect(service.url_changed?).to be_truthy
      end

      it 'returns false when the property has been re-assigned the same value' do
        service.url = 'http://url.com'
        service.validate
        expect(service.url_changed?).to be_falsy
      end
    end

    describe '{arg}_touched?' do
      it 'returns false when the property has not been assigned a new value' do
        service.username = 'new_username'
        service.validate
        expect(service.url_changed?).to be_falsy
      end

      it 'returns true when the property has been assigned a different value' do
        service.url = "http://example.com"
        service.validate
        expect(service.url_changed?).to be_truthy
      end

      it 'returns true when the property has been assigned a different value twice' do
        service.url = "http://example.com"
        service.url = "http://example.com"
        service.validate
        expect(service.url_changed?).to be_truthy
      end

      it 'returns true when the property has been re-assigned the same value' do
        service.url = 'http://url.com'
        expect(service.url_touched?).to be_truthy
      end

      it 'returns false when the property has been re-assigned the same value' do
        service.url = 'http://url.com'
        service.validate
        expect(service.url_changed?).to be_falsy
      end
    end

    describe 'data_fields_present?' do
      it 'returns true from the issue tracker service' do
        expect(service.data_fields_present?).to be true
      end
    end
  end

  context 'when data are stored in data_fields' do
    let(:service) do
      create(:jira_service, url: url, username: username)
    end

    it_behaves_like 'data fields'

    describe '{arg}_was?' do
      it 'returns nil' do
        service.url = 'http://example.com'
        service.validate
        expect(service.url_was).to be_nil
      end
    end
  end

  context 'when service and data_fields are not persisted' do
    let(:service) do
      JiraService.new
    end

    describe 'data_fields_present?' do
      it 'returns true' do
        expect(service.data_fields_present?).to be true
      end
    end
  end

  context 'when data are stored in properties' do
    let(:service) { create(:jira_service, :without_properties_callback, properties: properties) }

    it_behaves_like 'data fields'

    describe '{arg}_was?' do
      it 'returns nil when the property has not been assigned a new value' do
        service.username = 'new_username'
        service.validate
        expect(service.url_was).to be_nil
      end

      it 'returns initial value when the property has been assigned a different value' do
        service.url = 'http://example.com'
        service.validate
        expect(service.url_was).to eq('http://url.com')
      end

      it 'returns initial value when the property has been re-assigned the same value' do
        service.url = 'http://url.com'
        service.validate
        expect(service.url_was).to eq('http://url.com')
      end
    end
  end

  context 'when data are stored in both properties and data_fields' do
    let(:service) do
      create(:jira_service, :without_properties_callback, active: false, properties: properties).tap do |service|
        create(:jira_tracker_data, properties.merge(service: service))
      end
    end

    it_behaves_like 'data fields'

    describe '{arg}_was?' do
      it 'returns nil' do
        service.url = 'http://example.com'
        service.validate
        expect(service.url_was).to be_nil
      end
    end
  end
end

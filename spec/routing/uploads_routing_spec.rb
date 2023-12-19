# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Uploads', 'routing' do
  context 'for personal snippets' do
    it 'allows creating uploads for personal snippets' do
      expect(post('/uploads/personal_snippet?id=1')).to route_to(
        controller: 'uploads',
        action: 'create',
        model: 'personal_snippet',
        id: '1'
      )
    end
  end

  context 'for users' do
    it 'allows creating uploads for users' do
      expect(post('/uploads/user?id=1')).to route_to(
        controller: 'uploads',
        action: 'create',
        model: 'user',
        id: '1'
      )
    end
  end

  context 'for abuse reports' do
    it 'allows fetching uploaded files for abuse reports' do
      expect(get('/uploads/-/system/abuse_report/1/secret/test.png')).to route_to(
        controller: 'uploads',
        action: 'show',
        model: 'abuse_report',
        id: '1',
        secret: 'secret',
        filename: 'test.png'
      )
    end

    it 'allows creating uploads for abuse reports' do
      expect(post('/uploads/abuse_report?id=1')).to route_to(
        controller: 'uploads',
        action: 'create',
        model: 'abuse_report',
        id: '1'
      )
    end

    it 'allows authorizing uploads for abuse reports' do
      expect(post('/uploads/abuse_report/authorize')).to route_to(
        controller: 'uploads',
        action: 'authorize',
        model: 'abuse_report'
      )
    end

    it 'allows fetching abuse report screenshots' do
      expect(get('/uploads/-/system/abuse_report/screenshot/1/test.jpg')).to route_to(
        controller: 'uploads',
        action: 'show',
        model: 'abuse_report',
        id: '1',
        filename: 'test.jpg',
        mounted_as: 'screenshot'
      )
    end
  end

  context 'for alert management' do
    it 'allows fetching alert metric metric images' do
      expect(get('/uploads/-/system/alert_management_metric_image/file/1/test.jpg')).to route_to(
        controller: 'uploads',
        action: 'show',
        model: 'alert_management_metric_image',
        id: '1',
        filename: 'test.jpg',
        mounted_as: 'file'
      )
    end
  end

  context 'for organizations' do
    it 'allows fetching organization avatars' do
      expect(get('/uploads/-/system/organizations/organization_detail/avatar/1/test.jpg')).to route_to(
        controller: 'uploads',
        action: 'show',
        model: 'organizations/organization_detail',
        id: '1',
        filename: 'test.jpg',
        mounted_as: 'avatar'
      )
    end
  end

  it 'does not allow creating uploads for other models' do
    unroutable_models = UploadsController::MODEL_CLASSES.keys.compact - %w[personal_snippet user abuse_report]

    unroutable_models.each do |model|
      expect(post("/uploads/#{model}?id=1")).not_to be_routable
    end
  end
end

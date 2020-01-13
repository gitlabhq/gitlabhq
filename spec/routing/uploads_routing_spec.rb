# frozen_string_literal: true

require 'spec_helper'

describe 'Uploads', 'routing' do
  it 'allows creating uploads for personal snippets' do
    expect(post('/uploads/personal_snippet?id=1')).to route_to(
      controller: 'uploads',
      action: 'create',
      model: 'personal_snippet',
      id: '1'
    )
  end

  it 'allows creating uploads for users' do
    expect(post('/uploads/user?id=1')).to route_to(
      controller: 'uploads',
      action: 'create',
      model: 'user',
      id: '1'
    )
  end

  it 'does not allow creating uploads for other models' do
    unroutable_models = UploadsController::MODEL_CLASSES.keys.compact - %w(personal_snippet user)

    unroutable_models.each do |model|
      expect(post("/uploads/#{model}?id=1")).not_to be_routable
    end
  end

  describe 'legacy paths' do
    include RSpec::Rails::RequestExampleGroup

    it 'redirects project uploads to canonical path under project namespace' do
      expect(get('/uploads/namespace/project/12345/test.png')).to redirect_to('/namespace/project/uploads/12345/test.png')
    end
  end
end

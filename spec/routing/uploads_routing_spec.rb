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

  it 'does not allow creating uploads for other models' do
    UploadsController::MODEL_CLASSES.keys.compact.each do |model|
      next if model == 'personal_snippet'

      expect(post("/uploads/#{model}?id=1")).not_to be_routable
    end
  end
end

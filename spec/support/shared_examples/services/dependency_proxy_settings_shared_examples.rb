# frozen_string_literal: true

RSpec.shared_examples 'updating the dependency proxy group settings attributes' do |from: {}, to: {}|
  it 'updates the dependency proxy settings' do
    expect { subject }
      .to change { group_settings.reload.enabled }.from(from[:enabled]).to(to[:enabled])
  end
end

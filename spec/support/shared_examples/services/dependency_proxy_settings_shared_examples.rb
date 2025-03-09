# frozen_string_literal: true

RSpec.shared_examples 'updating the dependency proxy group settings attributes' do |from: {}, to: {}|
  it 'updates the dependency proxy settings' do
    old_identity = group_settings.identity
    old_secret = group_settings.secret

    expect { subject }
      .to change { group_settings.reload.enabled }.from(from[:enabled]).to(to[:enabled])

    if from[:identity] && to[:identity]
      expect(old_identity).to eq(from[:identity])
      expect(group_settings.identity).to eq(to[:identity])
    else
      expect(group_settings.identity).to eq(old_identity)
    end

    if from[:secret] && to[:secret]
      expect(old_secret).to eq(from[:secret])
      expect(group_settings.secret).to eq(to[:secret])
    else
      expect(group_settings.secret).to eq(old_secret)
    end
  end
end

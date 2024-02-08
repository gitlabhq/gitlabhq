# frozen_string_literal: true

RSpec.shared_examples Integrations::HasAvatar do
  describe '#avatar_url' do
    it 'returns the expected avatar URL' do
      expect(subject.avatar_url).to eq(ActionController::Base.helpers.image_path(
        "illustrations/third-party-logos/integrations-logos/#{subject.to_param}.svg"
      ))
    end
  end
end

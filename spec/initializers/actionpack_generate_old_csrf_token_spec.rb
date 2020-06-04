# frozen_string_literal: true

require 'spec_helper'

describe ActionController::Base, 'CSRF token generation patch', type: :controller do # rubocop:disable RSpec/FilePath
  let(:fixed_seed) { SecureRandom.random_bytes(described_class::AUTHENTICITY_TOKEN_LENGTH) }

  context 'global_csrf_token feature flag is enabled' do
    it 'generates 6.0.3.1 style CSRF token', :aggregate_failures do
      generated_token = controller.send(:form_authenticity_token)

      expect(valid_authenticity_token?(generated_token)).to be_truthy
      expect(compare_with_real_token(generated_token)).to be_falsey
      expect(compare_with_global_token(generated_token)).to be_truthy
    end
  end

  context 'global_csrf_token feature flag is disabled' do
    before do
      stub_feature_flags(global_csrf_token: false)
    end

    it 'generates 6.0.3 style CSRF token', :aggregate_failures do
      generated_token = controller.send(:form_authenticity_token)

      expect(valid_authenticity_token?(generated_token)).to be_truthy
      expect(compare_with_real_token(generated_token)).to be_truthy
      expect(compare_with_global_token(generated_token)).to be_falsey
    end
  end

  def compare_with_global_token(token)
    unmasked_token = controller.send :unmask_token, Base64.strict_decode64(token)

    controller.send(:compare_with_global_token, unmasked_token, session)
  end

  def compare_with_real_token(token)
    unmasked_token = controller.send :unmask_token, Base64.strict_decode64(token)

    controller.send(:compare_with_real_token, unmasked_token, session)
  end

  def valid_authenticity_token?(token)
    controller.send(:valid_authenticity_token?, session, token)
  end
end

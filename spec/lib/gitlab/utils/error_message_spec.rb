# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::ErrorMessage, feature_category: :error_tracking do
  let(:klass) do
    Class.new do
      include Gitlab::Utils::ErrorMessage
    end
  end

  subject(:object) { klass.new }

  describe 'error message' do
    subject { object.to_user_facing(string) }

    let(:string) { 'Error Message' }

    it "returns input prefixed with UF:" do
      is_expected.to eq 'UF: Error Message'
    end
  end
end

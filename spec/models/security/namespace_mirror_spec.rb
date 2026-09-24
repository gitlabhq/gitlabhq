# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::NamespaceMirror, feature_category: :organization do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
  end
end

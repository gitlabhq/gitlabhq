# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DisablesSti, feature_category: :shared do
  describe '.allow_legacy_sti_class' do
    it 'is nil by default' do
      expect(ApplicationRecord.allow_legacy_sti_class).to eq(nil)
    end

    it 'is true on legacy models' do
      expect(PersonalSnippet.allow_legacy_sti_class).to eq(true)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::NoteMetadata, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:note) }
  end

  describe 'validation' do
    it { is_expected.to validate_length_of(:email_participant).is_at_most(255) }
  end
end

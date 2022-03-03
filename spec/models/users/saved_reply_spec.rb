# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SavedReply do
  let_it_be(:saved_reply) { create(:saved_reply) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to([:user_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:content).is_at_most(10000) }
  end
end

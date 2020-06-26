# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::AlertUserMention do
  describe 'associations' do
    it { is_expected.to belong_to(:alert_management_alert) }
    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'has user mentions'
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::AlertUserMention do
  describe 'associations' do
    it do
      is_expected.to belong_to(:alert).class_name('::AlertManagement::Alert')
        .with_foreign_key(:alert_management_alert_id).inverse_of(:user_mentions)
    end

    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'has user mentions'
end

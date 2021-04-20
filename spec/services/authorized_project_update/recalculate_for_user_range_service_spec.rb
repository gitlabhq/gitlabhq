# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::RecalculateForUserRangeService do
  describe '#execute' do
    let_it_be(:users) { create_list(:user, 2) }

    it 'calls Users::RefreshAuthorizedProjectsService' do
      user_ids = users.map(&:id)

      User.where(id: user_ids).select(:id).each do |user|
        expect(Users::RefreshAuthorizedProjectsService).to(
          receive(:new).with(user, source: described_class.name).and_call_original)
      end

      range = user_ids.minmax
      described_class.new(*range).execute
    end
  end
end

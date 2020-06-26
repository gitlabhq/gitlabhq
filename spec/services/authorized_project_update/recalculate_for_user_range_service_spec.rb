# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::RecalculateForUserRangeService do
  describe '#execute' do
    let_it_be(:users) { create_list(:user, 2) }

    it 'calls Users::RefreshAuthorizedProjectsService' do
      users.each do |user|
        expect(Users::RefreshAuthorizedProjectsService).to(
          receive(:new).with(user).and_call_original)
      end

      range = users.map(&:id).minmax
      described_class.new(*range).execute
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::PeriodicRecalculateService do
  subject(:service) { described_class.new }

  describe '#execute' do
    let(:batch_size) { 2 }

    let_it_be(:users) { create_list(:user, 4) }

    before do
      stub_const('AuthorizedProjectUpdate::PeriodicRecalculateService::BATCH_SIZE', batch_size)

      User.delete([users[1], users[2]])
    end

    it 'calls AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker' do
      (1..User.maximum(:id)).each_slice(batch_size).with_index(1) do |batch, index|
        delay = AuthorizedProjectUpdate::PeriodicRecalculateService::DELAY_INTERVAL * index

        expect(AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker).to(
          receive(:perform_in).with(delay, *batch.minmax))
      end

      service.execute
    end
  end
end

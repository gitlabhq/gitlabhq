# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleFixIncorrectMaxSeatsUsed, :migration, feature_category: :purchase do
  let(:migration) { described_class.new }

  describe '#up' do
    it 'schedules a job on Gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      expect(migration).to receive(:migrate_in).with(1.hour, 'FixIncorrectMaxSeatsUsed')

      migration.up
    end

    it 'does not schedule any jobs when not Gitlab.com' do
      allow(Gitlab::CurrentSettings).to receive(:com?).and_return(false)

      expect(migration).not_to receive(:migrate_in)

      migration.up
    end
  end
end

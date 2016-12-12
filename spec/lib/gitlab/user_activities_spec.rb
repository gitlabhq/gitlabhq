require 'spec_helper'

describe Gitlab::UserActivities, :redis, lib: true do
  let(:user) { create(:user) }

  it 'shows the last user activities' do
    Timecop.freeze do
      Users::ActivityService.new(user, 'type').execute

      expect(described_class.query).to eq({ username: user.username,
                                            last_activity: DateTime.now })
    end
  end

  context 'paginated activities' do
    before do
      Timecop.scale(3600)

      7.times do
        Users::ActivityService.new(create(:user), 'type').execute
      end
    end

    after do
      Timecop.return
    end

    it 'shows the 5 oldest user activities paginated' do
      expect(described_class.query(per_page: 5).count).to eq(5)
    end

    it 'shows the 2 reamining user activities paginated' do
      expect(described_class.query(per_page: 5, page: 1).count).to eq(2)
    end

    it 'shows the oldest first' do
      # FIXME
      expect(described_class.query.first.second).to be < described_class.query.last.second
    end
  end

  context 'filter by date'do
    before do
      Timecop.freeze(Date.yesterday)
    end

    after do
      Timecop.return
    end

    it 'shows activities from yesterday' do
      expect(described_class.query(from: Date.yesterday).count).to eq(1)
    end

    it 'filter activities from today' do
      expect(described_class.query(from: Date.today).count).to eq(0)
    end
  end
end

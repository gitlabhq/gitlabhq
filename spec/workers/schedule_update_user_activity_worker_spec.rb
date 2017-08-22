require 'spec_helper'

describe ScheduleUpdateUserActivityWorker, :clean_gitlab_redis_shared_state do
  let(:now) { Time.now }

  before do
    Gitlab::UserActivities.record('1', now)
    Gitlab::UserActivities.record('2', now)
  end

  it 'schedules UpdateUserActivityWorker once' do
    expect(UpdateUserActivityWorker).to receive(:perform_async).with({ '1' => now.to_i.to_s, '2' => now.to_i.to_s })

    subject.perform
  end

  context 'when specifying a batch size' do
    it 'schedules UpdateUserActivityWorker twice' do
      expect(UpdateUserActivityWorker).to receive(:perform_async).with({ '1' => now.to_i.to_s })
      expect(UpdateUserActivityWorker).to receive(:perform_async).with({ '2' => now.to_i.to_s })

      subject.perform(1)
    end
  end
end

require 'spec_helper'

describe Gitlab::Mirror do
  before { Sidekiq::Logging.logger = nil }

  describe '#sync_times' do
    before { Timecop.freeze(DateTime.now.change(time)) }

    describe 'every fifteen minutes' do
      let!(:time) { { hour: 1, min: 15 } }

      it 'returns only fifteen minutes' do
        times = [Gitlab::Mirror::FIFTEEN]

        expect(described_class.sync_times).to match_array(times)
      end
    end

    describe 'at beginning of hour' do
      let!(:time) { { hour: 1 } }

      it 'returns only fifteen and hourly sync_times' do
        times = [Gitlab::Mirror::FIFTEEN, Gitlab::Mirror::HOURLY]

        expect(described_class.sync_times).to match_array(times)
      end
    end

    describe 'at beginning of th hour' do
      describe 'three' do
        let!(:time) { { hour: 3 } }

        it 'returns only fifteen hourly and three hour sync_times' do
          times = [Gitlab::Mirror::FIFTEEN, Gitlab::Mirror::HOURLY, Gitlab::Mirror::THREE]

          expect(described_class.sync_times).to match_array(times)
        end
      end

      describe 'six' do
        let!(:time) { { hour: 6 } }

        it 'returns only fifteen, hourly, three and six hour sync_times' do
          times = [Gitlab::Mirror::FIFTEEN, Gitlab::Mirror::HOURLY, Gitlab::Mirror::THREE, Gitlab::Mirror::SIX]

          expect(described_class.sync_times).to match_array(times)
        end
      end

      describe 'twelve' do
        let!(:time) { { hour: 12 } }

        it 'returns only fifteen, hourly, three, six and twelve hour sync_times' do
          times = [Gitlab::Mirror::FIFTEEN, Gitlab::Mirror::HOURLY, Gitlab::Mirror::THREE, Gitlab::Mirror::SIX, Gitlab::Mirror::TWELVE]

          expect(described_class.sync_times).to match_array(times)
        end
      end
    end

    describe 'at beginning of day' do
      let!(:time) { { hour: 0 } }

      it 'returns daily hourly and fifteen sync_times' do
        times = [Gitlab::Mirror::FIFTEEN, Gitlab::Mirror::HOURLY, Gitlab::Mirror::THREE, Gitlab::Mirror::SIX, Gitlab::Mirror::TWELVE, Gitlab::Mirror::DAILY]

        expect(described_class.sync_times).to match_array(times)
      end
    end

    after { Timecop.return }
  end

  describe '#configure_cron_job!' do
    let(:daily_cron)   { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::DAILY] }
    let(:twelve_cron)  { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::TWELVE] }
    let(:six_cron)     { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::SIX] }
    let(:three_cron)   { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::THREE] }
    let(:hourly_cron)  { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::HOURLY] }
    let(:fifteen_cron) { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::FIFTEEN] }

    describe 'with jobs already running' do
      def setup_mirrors_cron_job(current, updated_time)
        allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(current)
        Gitlab::Mirror.configure_cron_job!
        allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(updated_time)
      end

      describe 'with daily minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::HOURLY, Gitlab::Mirror::DAILY) }

        it 'changes cron of update_all_mirrors_worker to daily' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(hourly_cron).to(daily_cron)
        end
      end

      describe 'with twelve hour minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::DAILY, Gitlab::Mirror::TWELVE) }

        it 'changes cron of update_all_mirrors_worker to every twelve hours' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(daily_cron).to(twelve_cron)
        end
      end

      describe 'with six hour minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::DAILY, Gitlab::Mirror::SIX) }

        it 'changes cron of update_all_mirrors_worker to every six hours' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(daily_cron).to(six_cron)
        end
      end

      describe 'with three hour minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::DAILY, Gitlab::Mirror::THREE) }

        it 'changes cron of update_all_mirrors_worker to every three hours' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(daily_cron).to(three_cron)
        end
      end

      describe 'with hourly minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::DAILY, Gitlab::Mirror::HOURLY) }

        it 'changes cron of update_all_mirrors_worker to hourly' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(daily_cron).to(hourly_cron)
        end
      end

      describe 'with fifteen minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::DAILY, Gitlab::Mirror::FIFTEEN) }

        it 'changes cron of update_all_mirrors_worker to fifteen' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(daily_cron).to(fifteen_cron)
        end
      end
    end

    describe 'without jobs already running' do
      before do
        Sidekiq::Cron::Job.find("update_all_mirrors_worker").destroy
      end

      describe 'with daily minimum_mirror_sync_time' do
        before { allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(Gitlab::Mirror::DAILY) }

        it 'creates update_all_mirrors_worker with cron of daily sync_time' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(daily_cron)
        end
      end

      describe 'with twelve hours minimum_mirror_sync_time' do
        before { allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(Gitlab::Mirror::TWELVE) }

        it 'creates update_all_mirrors_worker with cron of every twelve hours sync_time' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(twelve_cron)
        end
      end

      describe 'with six hours minimum_mirror_sync_time' do
        before { allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(Gitlab::Mirror::SIX) }

        it 'creates update_all_mirrors_worker with cron of every six hours sync_time' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(six_cron)
        end
      end

      describe 'with three hours minimum_mirror_sync_time' do
        before { allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(Gitlab::Mirror::THREE) }

        it 'creates update_all_mirrors_worker with cron of every three hours sync_time' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(three_cron)
        end
      end

      describe 'with hourly minimum_mirror_sync_time' do
        before { allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(Gitlab::Mirror::HOURLY) }

        it 'creates update_all_mirrors_worker with cron of hourly sync_time' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(hourly_cron)
        end
      end

      describe 'with fifteen minimum_mirror_sync_time' do
        it 'creates update_all_mirrors_worker with cron of fifteen sync_time' do
          expect { described_class.configure_cron_job! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(fifteen_cron)
        end
      end
    end
  end

  describe '#at_beginning_of_day?' do
    it 'returns true if at beginning_of_day' do
      Timecop.freeze(DateTime.now.beginning_of_day)

      expect(described_class.at_beginning_of_day?).to be true
    end

    it 'returns true during the first 14 minutes of the day' do
      Timecop.freeze(DateTime.now.beginning_of_day + 14.minutes)

      expect(described_class.at_beginning_of_day?).to be true
    end

    it 'returns false if some time after the day started' do
      Timecop.freeze(DateTime.now.midday)

      expect(described_class.at_beginning_of_day?).to be false
    end

    after { Timecop.return }
  end

  describe '#at_beginning_of_hour?' do
    before { Timecop.freeze(DateTime.now.change(time)) }

    describe 'without hour mark' do
      describe 'at beginning of day' do
        let!(:time) { { hour: 0 } }

        it { expect(described_class.at_beginning_of_hour?).to be true }
      end

      describe 'at beginning of hour' do
        let!(:time) { { hour: 1 } }

        it { expect(described_class.at_beginning_of_hour?).to be true }
      end

      describe 'at beginning of hour' do
        let!(:time) { { hour: 1, min: 15 } }

        it { expect(described_class.at_beginning_of_hour?).to be false }
      end
    end

    describe 'with hour mark' do
      describe 'three' do
        let!(:time) { { hour: 3 } }

        it { expect(described_class.at_beginning_of_hour?(3)).to be true }

        describe 'with another hour' do
          let!(:time) { { hour: 4 } }

          it { expect(described_class.at_beginning_of_hour?(3)).to be false }
        end
      end

      describe 'six' do
        let!(:time) { { hour: 6 } }

        it { expect(described_class.at_beginning_of_hour?(6)).to be true }

        describe 'with another hour' do
          let!(:time) { { hour: 4 } }

          it { expect(described_class.at_beginning_of_hour?(6)).to be false }
        end
      end

      describe 'twelve' do
        let!(:time) { { hour: 12 } }

        it { expect(described_class.at_beginning_of_hour?(12)).to be true }

        describe 'with another hour' do
          let!(:time) { { hour: 4 } }

          it { expect(described_class.at_beginning_of_hour?(12)).to be false }
        end
      end
    end

    after { Timecop.return }
  end
end

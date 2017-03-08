require 'spec_helper'

describe Gitlab::Mirror do
  before { Sidekiq::Logging.logger = nil }

  describe '#sync_times' do
    describe 'at beginning of hour' do
      before { Timecop.freeze(DateTime.now.at_beginning_of_hour) }

      it 'returns only fifteen and hourly sync_times' do
        expect(Gitlab::Mirror.sync_times).to contain_exactly(Gitlab::Mirror::FIFTEEN, Gitlab::Mirror::HOURLY)
      end
    end

    describe 'at beginning of day' do
      before { Timecop.freeze(DateTime.now.at_beginning_of_day) }

      it 'returns daily hourly and fifteen sync_times' do
        expect(Gitlab::Mirror.sync_times).to contain_exactly(Gitlab::Mirror::DAILY, Gitlab::Mirror::HOURLY, Gitlab::Mirror::FIFTEEN)
      end
    end

    describe 'every fifteen minutes' do
      before { Timecop.freeze(DateTime.now.at_beginning_of_hour + 15.minutes) }

      it 'returns only fifteen minutes' do
        expect(Gitlab::Mirror.sync_times).to contain_exactly(Gitlab::Mirror::FIFTEEN)
      end
    end

    after { Timecop.return }
  end

  describe '#configure_cron_jobs!' do
    let(:daily_cron) { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::DAILY] }
    let(:hourly_cron) { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::HOURLY] }
    let(:fifteen_cron) { Gitlab::Mirror::SYNC_TIME_TO_CRON[Gitlab::Mirror::FIFTEEN] }

    describe 'with jobs already running' do
      def setup_mirrors_cron_job(current, updated_time)
        allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(current)
        Gitlab::Mirror.configure_cron_jobs!
        allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(updated_time)
      end

      describe 'with daily minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::HOURLY, Gitlab::Mirror::DAILY) }

        it 'changes cron of update_all_mirrors_worker to daily' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(hourly_cron).to(daily_cron)
        end

        it 'changes cron of update_all_remote_mirrors_worker to daily' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker").cron }.from(hourly_cron).to(daily_cron)
        end
      end

      describe 'with hourly minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::DAILY, Gitlab::Mirror::HOURLY) }

        it 'changes cron of update_all_mirrors_worker to daily' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(daily_cron).to(hourly_cron)
        end

        it 'changes cron of update_all_remote_mirrors_worker to daily' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker").cron }.from(daily_cron).to(hourly_cron)
        end
      end

      describe 'with fifteen minimum_mirror_sync_time' do
        before { setup_mirrors_cron_job(Gitlab::Mirror::DAILY, Gitlab::Mirror::FIFTEEN) }

        it 'changes cron of update_all_mirrors_worker to fifteen' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron }.from(daily_cron).to(fifteen_cron)
        end

        it 'changes cron of update_all_remote_mirrors_worker to fifteen' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker").cron }.from(daily_cron).to(fifteen_cron)
        end
      end
    end

    describe 'without jobs already running' do
      before do
        Sidekiq::Cron::Job.find("update_all_mirrors_worker").destroy
        Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker").destroy
      end

      describe 'with daily minimum_mirror_sync_time' do
        before { allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(Gitlab::Mirror::DAILY) }

        it 'creates update_all_mirrors_worker with cron of daily sync_time' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(daily_cron)
        end

        it 'creates update_all_remote_mirrors_worker with cron of daily sync_time' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker").cron).to eq(daily_cron)
        end
      end

      describe 'with hourly minimum_mirror_sync_time' do
        before { allow_any_instance_of(ApplicationSetting).to receive(:minimum_mirror_sync_time).and_return(Gitlab::Mirror::HOURLY) }

        it 'creates update_all_mirrors_worker with cron of hourly sync_time' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(hourly_cron)
        end

        it 'creates update_all_remote_mirrors_worker with cron of hourly sync_time' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker").cron).to eq(hourly_cron)
        end
      end

      describe 'with fifteen minimum_mirror_sync_time' do
        it 'creates update_all_mirrors_worker with cron of fifteen sync_time' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_mirrors_worker").cron).to eq(fifteen_cron)
        end

        it 'creates update_all_remote_mirrors_worker with cron of fifteen sync_time' do
          expect { Gitlab::Mirror.configure_cron_jobs! }.to change { Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker") }.from(nil).to(Sidekiq::Cron::Job)
          expect(Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker").cron).to eq(fifteen_cron)
        end
      end
    end
  end

  describe '#at_beginning_of_day?' do
    it 'returns true if at beginning_of_day' do
      Timecop.freeze(DateTime.now.at_beginning_of_day)

      expect(Gitlab::Mirror.at_beginning_of_day?).to be true
    end

    it 'returns false if at beginning of hour' do
      Timecop.freeze(DateTime.now.at_beginning_of_hour)

      expect(Gitlab::Mirror.at_beginning_of_day?).to be false
    end

    it 'returns false in every 15 minute mark' do
      Timecop.freeze(DateTime.now.at_beginning_of_hour + 15.minutes)

      expect(Gitlab::Mirror.at_beginning_of_day?).to be false
    end

    after { Timecop.return }
  end

  describe '#at_beginning_of_hour?' do
    it 'returns true if at beginning of day' do
      Timecop.freeze(DateTime.now.at_beginning_of_day)

      expect(Gitlab::Mirror.at_beginning_of_day?).to be true
    end

    it 'returns true if at beginning of hour' do
      Timecop.freeze(DateTime.now.at_beginning_of_hour)

      expect(Gitlab::Mirror.at_beginning_of_hour?).to be true
    end

    it 'returns false in every 15 minute mark' do
      Timecop.freeze(DateTime.now.at_beginning_of_hour + 15.minutes)

      expect(Gitlab::Mirror.at_beginning_of_hour?).to be false
    end

    after { Timecop.return }
  end
end

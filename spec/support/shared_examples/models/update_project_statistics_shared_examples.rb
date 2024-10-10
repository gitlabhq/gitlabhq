# frozen_string_literal: true

RSpec.shared_examples 'UpdateProjectStatistics' do |with_counter_attribute|
  let(:project) { subject.project }
  let(:project_statistics_name) { described_class.project_statistics_name }
  let(:statistic_attribute) { described_class.statistic_attribute }

  def reload_stat
    project.statistics.reload.send(project_statistics_name).to_i
  end

  def read_attribute
    subject.read_attribute(statistic_attribute).to_i
  end

  def read_pending_increment
    Gitlab::Redis::SharedState.with do |redis|
      key = project.statistics.counter(project_statistics_name).key
      redis.get(key).to_i
    end
  end

  it { is_expected.to be_new_record }

  def expect_flush_counter_increments_worker_performed
    expect(FlushCounterIncrementsWorker)
      .to receive(:perform_in)
      .with(Gitlab::Counters::BufferedCounter::WORKER_DELAY, project.statistics.class.name, project.statistics.id, project_statistics_name.to_s)

    yield

    # simulate worker running now
    expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async)
    FlushCounterIncrementsWorker.new.perform(project.statistics.class.name, project.statistics.id, project_statistics_name)
  end

  if with_counter_attribute
    context 'when statistic is a counter attribute', :clean_gitlab_redis_shared_state do
      context 'when creating' do
        it 'stores pending increments for async update' do
          initial_stat = reload_stat
          expected_increment = read_attribute

          expect_flush_counter_increments_worker_performed do
            subject.save!

            expect(read_pending_increment).to eq(expected_increment)
            expect(expected_increment).to be > initial_stat
            expect(expected_increment).to be_positive
          end
        end
      end

      context 'when updating' do
        let(:delta) { 42 }

        before do
          subject.save!
          redis_shared_state_cleanup!
        end

        it 'stores pending increments for async update' do
          expected_increment = have_attributes(amount: delta, ref: subject.id)

          expect(ProjectStatistics)
            .to receive(:increment_statistic)
            .with(project, project_statistics_name, expected_increment)
            .and_call_original

          subject.write_attribute(statistic_attribute, read_attribute + delta)

          expect_flush_counter_increments_worker_performed do
            subject.save!

            expect(read_pending_increment).to eq(delta)
          end
        end

        it 'avoids N + 1 queries' do
          subject.write_attribute(statistic_attribute, read_attribute + delta)

          control_count = ActiveRecord::QueryRecorder.new do
            subject.save!
          end

          subject.write_attribute(statistic_attribute, read_attribute + delta)

          expect do
            subject.save!
          end.not_to exceed_query_limit(control_count)
        end
      end

      context 'when destroying' do
        before do
          subject.save!
          redis_shared_state_cleanup!
        end

        it 'stores pending increment for async update' do
          initial_stat = reload_stat
          expected_increment = -read_attribute

          expect_flush_counter_increments_worker_performed do
            subject.destroy!

            expect(read_pending_increment).to eq(expected_increment)
            expect(expected_increment).to be < initial_stat
            expect(expected_increment).to be_negative
          end
        end

        context 'when it is destroyed from the project level' do
          it 'does not store pending increments for async update' do
            expect { Projects::DestroyService.new(project, project.first_owner).execute }.not_to change { read_pending_increment }
          end

          it 'does not schedule a namespace statistics worker' do
            expect(Namespaces::ScheduleAggregationWorker)
              .not_to receive(:perform_async)

            expect(Projects::DestroyService.new(project, project.first_owner).execute).to eq(true)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'UpdateProjectStatistics' do
  let(:project) { subject.project }
  let(:project_statistics_name) { described_class.project_statistics_name }
  let(:statistic_attribute) { described_class.statistic_attribute }

  def reload_stat
    project.statistics.reload.send(project_statistics_name).to_i
  end

  def read_attribute
    subject.read_attribute(statistic_attribute).to_i
  end

  it { is_expected.to be_new_record }

  context 'when creating' do
    it 'updates the project statistics' do
      delta = read_attribute

      expect { subject.save! }
        .to change { reload_stat }
        .by(delta)
    end

    it 'schedules a namespace statistics worker' do
      expect(Namespaces::ScheduleAggregationWorker)
        .to receive(:perform_async).once

      subject.save!
    end

    context 'when feature flag is disabled for the namespace' do
      it 'does not schedules a namespace statistics worker' do
        namespace = subject.project.root_ancestor

        stub_feature_flags(update_statistics_namespace: false, namespace: namespace)

        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        subject.save!
      end
    end
  end

  context 'when updating' do
    let(:delta) { 42 }

    before do
      subject.save!
    end

    it 'updates project statistics' do
      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .and_call_original

      subject.write_attribute(statistic_attribute, read_attribute + delta)

      expect { subject.save! }
        .to change { reload_stat }
        .by(delta)
    end

    it 'schedules a namespace statistics worker' do
      expect(Namespaces::ScheduleAggregationWorker)
        .to receive(:perform_async).once

      subject.write_attribute(statistic_attribute, read_attribute + delta)
      subject.save!
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

    context 'when the feature flag is disabled for the namespace' do
      it 'does not schedule a namespace statistics worker' do
        namespace = subject.project.root_ancestor

        stub_feature_flags(update_statistics_namespace: false, namespace: namespace)

        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        subject.write_attribute(statistic_attribute, read_attribute + delta)
        subject.save!
      end
    end
  end

  context 'when destroying' do
    before do
      subject.save!
    end

    it 'updates the project statistics' do
      delta = -read_attribute

      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .and_call_original

      expect { subject.destroy! }
        .to change { reload_stat }
        .by(delta)
    end

    it 'schedules a namespace statistics worker' do
      expect(Namespaces::ScheduleAggregationWorker)
        .to receive(:perform_async).once

      subject.destroy!
    end

    context 'when it is destroyed from the project level' do
      it 'does not update the project statistics' do
        expect(ProjectStatistics)
          .not_to receive(:increment_statistic)

        project.update(pending_delete: true)
        project.destroy!
      end

      it 'does not schedule a namespace statistics worker' do
        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        project.update(pending_delete: true)
        project.destroy!
      end
    end

    context 'when feature flag is disabled for the namespace' do
      it 'does not schedule a namespace statistics worker' do
        namespace = subject.project.root_ancestor

        stub_feature_flags(update_statistics_namespace: false, namespace: namespace)

        expect(Namespaces::ScheduleAggregationWorker)
          .not_to receive(:perform_async)

        subject.destroy!
      end
    end
  end
end

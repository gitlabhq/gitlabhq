# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::RebalancingWorker, feature_category: :team_planning do
  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue) { create(:issue, project: project) }

    shared_examples 'running the worker' do
      it 'runs an instance of Issues::RelativePositionRebalancingService' do
        service = double(execute: nil)
        service_param = arguments.second.present? ? kind_of(Project.id_in([project]).class) : kind_of(group&.all_projects.class)

        expect(Issues::RelativePositionRebalancingService).to receive(:new).with(service_param).and_return(service)

        described_class.new.perform(*arguments)
      end

      it 'anticipates there being too many concurent rebalances' do
        service = double
        service_param = arguments.second.present? ? kind_of(Project.id_in([project]).class) : kind_of(group&.all_projects.class)

        allow(service).to receive(:execute).and_raise(Issues::RelativePositionRebalancingService::TooManyConcurrentRebalances)
        expect(Issues::RelativePositionRebalancingService).to receive(:new).with(service_param).and_return(service)
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(Issues::RelativePositionRebalancingService::TooManyConcurrentRebalances, include(project_id: arguments.second, root_namespace_id: arguments.third))

        described_class.new.perform(*arguments)
      end

      it 'takes no action if the value is nil' do
        expect(Issues::RelativePositionRebalancingService).not_to receive(:new)
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        described_class.new.perform # all arguments are nil
      end

      it 'does not schedule a new rebalance if it finished under 1h ago' do
        container_type = arguments.second.present? ? ::Gitlab::Issues::Rebalancing::State::PROJECT : ::Gitlab::Issues::Rebalancing::State::NAMESPACE
        container_id = arguments.second || arguments.third

        Gitlab::Redis::SharedState.with do |redis|
          redis.set(::Gitlab::Issues::Rebalancing::State.send(:recently_finished_key, container_type, container_id), true)
        end

        expect(Issues::RelativePositionRebalancingService).not_to receive(:new)
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        described_class.new.perform(*arguments)
      end
    end

    shared_examples 'safely handles non-existent ids' do
      it 'anticipates the inability to find the issue' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(ArgumentError, include(project_id: arguments.second, root_namespace_id: arguments.third))
        expect(Issues::RelativePositionRebalancingService).not_to receive(:new)

        described_class.new.perform(*arguments)
      end
    end

    context 'without root_namespace param' do
      it_behaves_like 'running the worker' do
        let(:arguments) { [-1, project.id] }
      end

      it_behaves_like 'safely handles non-existent ids' do
        let(:arguments) { [nil, -1] }
      end

      include_examples 'an idempotent worker' do
        let(:job_args) { [-1, project.id] }
      end

      include_examples 'an idempotent worker' do
        let(:job_args) { [nil, -1] }
      end
    end

    context 'with root_namespace param' do
      it_behaves_like 'running the worker' do
        let(:arguments) { [nil, nil, group.id] }
      end

      it_behaves_like 'safely handles non-existent ids' do
        let(:arguments) { [nil, nil, -1] }
      end

      include_examples 'an idempotent worker' do
        let(:job_args) { [nil, nil, group.id] }
      end

      include_examples 'an idempotent worker' do
        let(:job_args) { [nil, nil, -1] }
      end
    end
  end

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    expect(described_class.get_deduplication_options).to include({ including_scheduled: true })
  end
end

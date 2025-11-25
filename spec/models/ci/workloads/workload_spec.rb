# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Workloads::Workload, feature_category: :continuous_integration do
  subject(:workload) { create(:ci_workload) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:pipeline) }

  it { is_expected.to validate_presence_of(:partition_id) }
  it { is_expected.to validate_presence_of(:pipeline) }
  it { is_expected.to validate_presence_of(:project) }

  describe 'partitioning' do
    context 'with pipeline' do
      let(:pipeline) { build(:ci_pipeline, partition_id: 123) }
      let(:workload) { build(:ci_workload, pipeline: pipeline) }

      it 'copies the partition_id from pipeline' do
        expect { workload.valid? }.to change { workload.partition_id }.to(123)
      end

      context 'when it is already set' do
        let(:workload) { build(:ci_workload, pipeline: pipeline, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { workload.valid? }.not_to change { workload.partition_id }
        end
      end
    end

    context 'without pipeline' do
      subject(:workload) { build(:ci_workload, pipeline: nil, project: build_stubbed(:project)) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { workload.valid? }.not_to change { workload.partition_id }
      end
    end
  end

  context 'with loose foreign key on ci_stages.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_workload, project: parent) }
    end
  end

  describe '#logs_url' do
    context 'when pipeline has logs' do
      let!(:log) { create(:ci_build, pipeline: workload.pipeline) }

      it 'returns the log url' do
        allow(Gitlab::Routing).to receive_message_chain(:url_helpers, :project_job_url)
          .with(workload.project, log).and_return('log-url')

        expect(workload.logs_url).to eq('log-url')
      end
    end

    context 'when pipeline has no logs' do
      it 'returns nil' do
        expect(workload.logs_url).to be_nil
      end
    end

    context 'when pipeline has multiple logs' do
      let!(:second_job) { create(:ci_build, pipeline: workload.pipeline) }
      let!(:first_job) { create(:ci_build, pipeline: workload.pipeline) }

      it 'returns the url of the first job by id' do
        allow(Gitlab::Routing).to receive_message_chain(:url_helpers, :project_job_url)
          .with(workload.project, second_job).and_return('logs-url')

        expect(workload.logs_url).to eq('logs-url')
      end
    end
  end

  describe 'state transitions' do
    let_it_be(:workload_for_aasm) { build(:ci_workload) }

    using RSpec::Parameterized::TableSyntax
    where(:status, :can_finish, :can_drop) do
      0 | true  | true
      3 | false | true
      4 | true  | false
    end

    with_them do
      it 'adheres to state machine rules', :aggregate_failures do
        workload_for_aasm.status = status

        expect(workload_for_aasm.can_finish?).to eq(can_finish)
        expect(workload_for_aasm.can_drop?).to eq(can_drop)
      end
    end
  end
end

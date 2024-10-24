# frozen_string_literal: true

RSpec.shared_examples 'dependency_proxy_cleanup_worker' do
  let_it_be(:group) { create(:group) }

  let(:worker) { described_class.new }

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has :none deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:none)
  end

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work }

    context 'with no work to do' do
      it { is_expected.to be_nil }
    end

    context 'with work to do' do
      let_it_be(:artifact1) { create(factory_type, :pending_destruction, group: group) }
      let_it_be(:artifact2) { create(factory_type, :pending_destruction, group: group, updated_at: 6.months.ago, created_at: 2.years.ago) }
      let_it_be_with_reload(:artifact3) { create(factory_type, :pending_destruction, group: group, updated_at: 1.year.ago, created_at: 1.year.ago) }
      let_it_be(:artifact4) { create(factory_type, group: group, updated_at: 2.years.ago, created_at: 2.years.ago) }

      it 'deletes the oldest artifact pending destruction based on updated_at', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done).with("#{factory_type}_id".to_sym, artifact3.id)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:group_id, group.id)

        expect { perform_work }.to change { artifact1.class.count }.by(-1)
      end
    end
  end

  describe '#max_running_jobs' do
    let(:capacity) { 5 }

    subject { worker.max_running_jobs }

    before do
      stub_application_setting(dependency_proxy_ttl_group_policy_worker_capacity: capacity)
    end

    it { is_expected.to eq(capacity) }
  end

  describe '#remaining_work_count' do
    before(:context) do
      create_list(factory_type, 3, :pending_destruction, group: group)
    end

    subject { worker.remaining_work_count }

    it { is_expected.to eq(3) }
  end
end

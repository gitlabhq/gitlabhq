# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::TraversalHierarchy, type: :model, feature_category: :groups_and_projects do
  let!(:root) { create(:group, :with_hierarchy, children: 2, depth: 3) }

  shared_context 'with broken hierarchy' do
    before do
      Namespace.update_all(traversal_ids: [])
    end
  end

  shared_examples 'sync_traversal_ids! with shared lock behavior' do
    it 'changes the lock timeout' do
      recorded_queries = ActiveRecord::QueryRecorder.new

      recorded_queries.record { subject }
      expect(recorded_queries.log).to include a_string_matching 'LOCK_TIMEOUT'
    end

    context 'when record is already locked' do
      let(:msg) { 'PG::QueryCanceled: ERROR:  canceling statement due to statement timeout' }
      let(:namespace) { instance_double(Namespace) }

      before do
        allow(lock_record).to receive(:becomes).with(Namespace).and_return(namespace)
        allow(namespace).to receive(:lock!).and_raise(ActiveRecord::QueryCanceled.new(msg))
      end

      it { expect { subject }.to raise_error(ActiveRecord::QueryCanceled, msg) }

      it 'increment db_query_timeout counter' do
        expect do
          subject
        rescue StandardError
          nil
        end.to change { db_query_timeout_total('Namespace#sync_traversal_ids!') }.by(1)
      end
    end

    context 'when deadlocked' do
      let(:namespace) { instance_double(Namespace) }

      before do
        allow(lock_record).to receive(:becomes).with(Namespace).and_return(namespace)
        allow(namespace).to receive(:lock!) { raise ActiveRecord::Deadlocked }
      end

      it { expect { subject }.to raise_error(ActiveRecord::Deadlocked) }

      it 'increment db_deadlock counter' do
        expect do
          subject
        rescue StandardError
          nil
        end.to change { db_deadlock_total('Namespace#sync_traversal_ids!') }.by(1)
      end
    end
  end

  describe '.for_namespace' do
    let(:hierarchy) { described_class.for_namespace(group) }

    context 'with root group' do
      let(:group) { root }

      it { expect(hierarchy.root).to eq root }
    end

    context 'with child group' do
      let(:group) { root.children.first.children.first }

      it { expect(hierarchy.root).to eq root }
    end

    context 'with group outside of hierarchy' do
      let(:group) { create(:group) }

      it { expect(hierarchy.root).not_to eq root }
    end
  end

  describe '.new' do
    let(:hierarchy) { described_class.new(group) }

    context 'with root group' do
      let(:group) { root }

      it { expect(hierarchy.root).to eq root }
    end

    context 'with child group' do
      let(:group) { root.children.first }

      it { expect { hierarchy }.to raise_error(StandardError, 'Must specify a root node') }
    end
  end

  describe '.sync_traversal_ids!', :lock_recorder do
    include_context 'with broken hierarchy'

    let(:hierarchy) { described_class.new(root) }
    let(:child) { root.children.first }

    subject { described_class.sync_traversal_ids!(child) }

    it 'synchronized traversal_ids for branch' do
      all_namespaces = root.recursive_self_and_descendants.to_a

      expect { subject }.to change { hierarchy.incorrect_traversal_ids }
                        .from(match_array(all_namespaces))
                        .to(match_array(all_namespaces - child.recursive_self_and_descendants))
    end

    it 'locks self and ancestors' do
      expect { subject }.to lock_rows(
        root => 'FOR SHARE',
        child => 'FOR NO KEY UPDATE'
      )
    end

    it_behaves_like 'sync_traversal_ids! with shared lock behavior' do
      let(:lock_record) { child }
    end
  end

  describe '.recursive_traversal_ids' do
    let!(:child) { root.children.first }
    let!(:child_recursive_traversal_ids) do
      child.self_and_descendants.pluck(:id, :traversal_ids).map do |id, traversal_ids|
        { "id" => id, "traversal_ids" => "{#{traversal_ids.join(',')}}" }
      end
    end

    let(:sql) { described_class.recursive_traversal_ids(child) }

    subject(:result) { Namespace.connection.exec_query(sql) }

    include_context 'with broken hierarchy' do
      it { expect(result).to match_array child_recursive_traversal_ids }
    end
  end

  describe '#incorrect_traversal_ids' do
    include_context 'with broken hierarchy'

    let!(:hierarchy) { described_class.new(root) }

    subject { hierarchy.incorrect_traversal_ids }

    it { is_expected.to match_array Namespace.all }
  end

  describe '#sync_traversal_ids!', :lock_recorder do
    include_context 'with broken hierarchy'

    let!(:hierarchy) { described_class.new(root) }

    subject { hierarchy.sync_traversal_ids! }

    it_behaves_like 'hierarchy with traversal_ids' do
      before do
        subject
      end
    end

    it 'locks the root ancestor' do
      expect { subject }.to lock_row(root => 'FOR NO KEY UPDATE')
    end

    it_behaves_like 'sync_traversal_ids! with shared lock behavior' do
      let(:lock_record) { root }
    end
  end

  def db_query_timeout_total(source)
    Gitlab::Metrics
      .counter(:db_query_timeout, 'Counts the times the query timed out')
      .get(source: source)
  end

  def db_deadlock_total(source)
    Gitlab::Metrics
      .counter(:db_deadlock, 'Counts the times we have deadlocked in the database')
      .get(source: source)
  end
end

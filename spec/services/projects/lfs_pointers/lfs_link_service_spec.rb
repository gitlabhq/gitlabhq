# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::LfsPointers::LfsLinkService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, lfs_enabled: true) }
  let_it_be(:lfs_objects_project) { create_list(:lfs_objects_project, 2, project: project) }

  let(:new_oids) { { 'oid1' => 123, 'oid2' => 125 } }
  let(:all_oids) { LfsObject.pluck(:oid, :size).to_h.merge(new_oids) }
  let(:new_lfs_object) { create(:lfs_object) }
  let(:new_oid_list) { all_oids.merge(new_lfs_object.oid => new_lfs_object.size) }

  subject { described_class.new(project) }

  before do
    allow(project).to receive(:lfs_enabled?).and_return(true)
  end

  describe '.batch_size' do
    subject { described_class.batch_size }

    it { is_expected.to eq(1000) }

    context 'when GITLAB_LFS_LINK_BATCH_SIZE env variable is provided' do
      before do
        stub_env('GITLAB_LFS_LINK_BATCH_SIZE', 1)
      end

      it 'uses provided value' do
        is_expected.to eq(1)
      end
    end
  end

  describe '#execute' do
    it 'raises an error when trying to link too many objects at once' do
      stub_const("#{described_class}::MAX_OIDS", 5)

      oids = Array.new(described_class::MAX_OIDS) { |i| "oid-#{i}" }
      oids << 'the straw'

      expect(Gitlab::Metrics::Lfs).to receive_message_chain(:validate_link_objects_error_rate, :increment).with(
        error: true, labels: {})
      expect { subject.execute(oids) }.to raise_error(described_class::TooManyOidsError)
    end

    it 'executes a block after validation and before execution' do
      block = instance_double(Proc)

      expect(subject).to receive(:validate!).ordered
      expect(block).to receive(:call).ordered
      expect(subject).to receive(:link_existing_lfs_objects).ordered

      subject.execute([]) do
        block.call
      end
    end

    it 'links existing lfs objects to the project' do
      expect(Gitlab::Metrics::Lfs).to receive_message_chain(:validate_link_objects_error_rate, :increment).with(
        error: false, labels: {})
      expect(project.lfs_objects.count).to eq 2

      linked = subject.execute(new_oid_list.keys)

      expect(project.lfs_objects.count).to eq 3
      expect(linked.size).to eq 3
    end

    it 'returns linked oids' do
      linked = lfs_objects_project.map(&:lfs_object).map(&:oid) << new_lfs_object.oid

      expect(Gitlab::Metrics::Lfs).to receive_message_chain(:validate_link_objects_error_rate, :increment).with(
        error: false, labels: {})

      expect(subject.execute(new_oid_list.keys)).to contain_exactly(*linked)
    end

    it 'links in batches' do
      stub_env('GITLAB_LFS_LINK_BATCH_SIZE', 3)

      expect(Gitlab::Metrics::Lfs).to receive_message_chain(:validate_link_objects_error_rate, :increment).with(
        error: false, labels: {})

      expect(::Import::Framework::Logger).to receive(:info).with(
        class: described_class.name,
        project_id: project.id,
        project_path: project.full_path,
        lfs_objects_linked_count: 7,
        iterations: 3
      )

      lfs_objects = create_list(:lfs_object, 7)
      linked = subject.execute(lfs_objects.pluck(:oid))

      expect(project.lfs_objects.count).to eq 9
      expect(linked.size).to eq 7
    end

    it 'only queries for the batch that will be processed', :aggregate_failures do
      stub_env('GITLAB_LFS_LINK_BATCH_SIZE', 1)
      oids = %w[one two]

      expect(Gitlab::Metrics::Lfs).to receive_message_chain(:validate_link_objects_error_rate, :increment).with(
        error: false, labels: {})
      expect(LfsObject).to receive(:for_oids).with(%w[one]).once.and_call_original
      expect(LfsObject).to receive(:for_oids).with(%w[two]).once.and_call_original

      subject.execute(oids)
    end

    it 'only queries 3 times' do
      # make sure that we don't count the queries in the setup
      new_oid_list

      expect(Gitlab::Metrics::Lfs).to receive_message_chain(:validate_link_objects_error_rate, :increment).with(
        error: false, labels: {})

      # These are repeated for each batch of oids: maximum (MAX_OIDS / BATCH_SIZE) times
      # 1. Load the batch of lfs object ids that we might know already
      # 2. Load the objects that have not been linked to the project yet
      # 3. Insert the lfs_objects_projects for that batch
      expect { subject.execute(new_oid_list.keys) }.not_to exceed_query_limit(3)
    end

    context 'when MAX_OIDS is 5' do
      let(:max_oids) { 5 }
      let(:oids) { Array.new(max_oids) { |i| "oid-#{i}" } }

      before do
        stub_const("#{described_class}::MAX_OIDS", max_oids)
      end

      it 'does not raise an error when trying to link exactly the OID limit' do
        expect(Gitlab::Metrics::Lfs).to receive_message_chain(:validate_link_objects_error_rate, :increment).with(
          error: false, labels: {})
        expect { subject.execute(oids) }.not_to raise_error
      end

      it 'raises an error when trying to link more than OID limit' do
        oids << 'the straw'

        expect(Gitlab::Metrics::Lfs).to receive_message_chain(:validate_link_objects_error_rate, :increment).with(
          error: true, labels: {})
        expect { subject.execute(oids) }.to raise_error(described_class::TooManyOidsError)
      end
    end
  end
end

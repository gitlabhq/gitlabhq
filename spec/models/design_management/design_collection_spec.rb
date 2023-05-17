# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::DesignCollection do
  include DesignManagementTestHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:issue, refind: true) { create(:issue) }

  subject(:collection) { described_class.new(issue) }

  describe ".find_or_create_design!" do
    it "finds an existing design" do
      design = create(:design, issue: issue, filename: 'world.png')

      expect(collection.find_or_create_design!(filename: 'world.png')).to eq(design)
    end

    it "creates a new design if one didn't exist" do
      expect(issue.designs.size).to eq(0)

      new_design = collection.find_or_create_design!(filename: 'world.png')

      expect(issue.designs.size).to eq(1)
      expect(new_design.filename).to eq('world.png')
      expect(new_design.issue).to eq(issue)
    end

    it "only queries the designs once" do
      create(:design, issue: issue, filename: 'hello.png')
      create(:design, issue: issue, filename: 'world.jpg')

      expect do
        collection.find_or_create_design!(filename: 'hello.png')
        collection.find_or_create_design!(filename: 'world.jpg')
      end.not_to exceed_query_limit(1)
    end

    it 'inserts the design after any existing designs' do
      design1 = collection.find_or_create_design!(filename: 'design1.jpg')
      design1.update!(relative_position: 100)

      design2 = collection.find_or_create_design!(filename: 'design2.jpg')

      expect(collection.designs.ordered).to eq([design1, design2])
    end
  end

  describe "#copy_state", :clean_gitlab_redis_shared_state do
    it "defaults to ready" do
      expect(collection).to be_copy_ready
    end

    it "persists its state changes between initializations" do
      collection.start_copy!

      expect(described_class.new(issue)).to be_copy_in_progress
    end

    where(:state, :can_start, :can_end, :can_error, :can_reset) do
      "ready"       | true  | false | true  | true
      "in_progress" | false | true  | true  | true
      "error"       | false | false | false | true
    end

    with_them do
      it "maintains state machine transition rules", :aggregate_failures do
        collection.copy_state = state

        expect(collection.can_start_copy?).to eq(can_start)
        expect(collection.can_end_copy?).to eq(can_end)
      end
    end

    describe "clearing the redis cached state when state changes back to ready" do
      def redis_copy_state
        Gitlab::Redis::SharedState.with do |redis|
          redis.get(collection.send(:copy_state_cache_key))
        end
      end

      def fire_state_events(*events)
        events.each do |event|
          collection.fire_copy_state_event(event)
        end
      end

      it "clears the cached state on end_copy!", :aggregate_failures do
        fire_state_events(:start)

        expect { collection.end_copy! }.to change { redis_copy_state }.from("in_progress").to(nil)
        expect(collection).to be_copy_ready
      end

      it "clears the cached state on reset_copy!", :aggregate_failures do
        fire_state_events(:start, :error)

        expect { collection.reset_copy! }.to change { redis_copy_state }.from("error").to(nil)
        expect(collection).to be_copy_ready
      end
    end
  end

  describe "#empty?" do
    it "is true when the design collection has no designs" do
      expect(collection).to be_empty
    end

    it "is false when the design collection has designs" do
      create(:design, issue: issue)

      expect(collection).not_to be_empty
    end
  end

  describe "#versions" do
    it "includes versions for all designs" do
      version_1 = create(:design_version)
      version_2 = create(:design_version)
      other_version = create(:design_version)
      create(:design, issue: issue, versions: [version_1])
      create(:design, issue: issue, versions: [version_2])
      create(:design, versions: [other_version])

      expect(collection.versions).to contain_exactly(version_1, version_2)
    end
  end

  describe "#repository" do
    it "builds a design repository" do
      expect(collection.repository).to be_a(DesignManagement::GitRepository)
    end
  end

  describe '#designs_by_filename' do
    let(:designs) { create_list(:design, 5, :with_file, issue: issue) }
    let(:filenames) { designs.map(&:filename) }
    let(:query) { subject.designs_by_filename(filenames) }

    it 'finds all the designs with those filenames on this issue' do
      expect(query).to have_attributes(size: 5)
    end

    it 'only makes a single query' do
      designs.each(&:id)
      expect { query }.not_to exceed_query_limit(1)
    end

    context 'some are deleted' do
      before do
        delete_designs(*designs.sample(2))
      end

      it 'takes deletion into account' do
        expect(query).to have_attributes(size: 3)
      end
    end
  end
end

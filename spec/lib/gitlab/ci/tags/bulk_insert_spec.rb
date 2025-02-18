# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Tags::BulkInsert, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be_with_refind(:job) { create(:ci_build, :unique_name, pipeline: pipeline) }
  let_it_be_with_refind(:other_job) { create(:ci_build, :unique_name, pipeline: pipeline) }

  let_it_be_with_refind(:runner) { create(:ci_runner) }
  let_it_be_with_refind(:other_runner) { create(:ci_runner, :project_type, projects: [project]) }

  let(:statuses) { [taggable, other_taggable] }
  let(:config) { nil }

  subject(:service) { described_class.new(statuses, config: config) }

  where(:taggable_class, :taggable, :other_taggable, :tagging_class, :taggable_id_column, :partition_column,
    :expected_configuration) do
    Ci::Build  | ref(:job)    | ref(:other_job)    | Ci::BuildTag      | :build_id  | :partition_id |
      described_class::BuildsTagsConfiguration
    Ci::Runner | ref(:runner) | ref(:other_runner) | Ci::RunnerTagging | :runner_id | :runner_type  |
      described_class::RunnerTaggingsConfiguration
  end

  with_them do
    describe '.bulk_insert_tags!' do
      let(:inserter) { instance_double(described_class) }

      it 'delegates to bulk insert class' do
        expect(described_class)
          .to receive(:new)
          .with(statuses, config: nil)
          .and_return(inserter)

        expect(inserter).to receive(:insert!)

        described_class.bulk_insert_tags!(statuses)
      end
    end

    describe '#insert!' do
      it 'generates a valid config' do
        expect(service.config).to be_a(expected_configuration)
      end

      context 'without tags' do
        it { expect(service.insert!).to be_truthy }
      end

      context 'with tags' do
        before do
          taggable.tag_list = %w[tag1 tag2]
          other_taggable.tag_list = %w[tag2 tag3 tag4]
        end

        it 'persists tags' do
          expect(service.insert!).to be_truthy

          expect(taggable.reload.tag_list).to match_array(%w[tag1 tag2])
          expect(other_taggable.reload.tag_list).to match_array(%w[tag2 tag3 tag4])
        end

        it 'persists taggings' do
          service.insert!

          expect(taggable.taggings.size).to eq(2)
          expect(other_taggable.taggings.size).to eq(3)

          expect(taggable_class.tagged_with('tag1')).to include(taggable)
          expect(taggable_class.tagged_with('tag2')).to include(taggable, other_taggable)
          expect(taggable_class.tagged_with('tag3')).to include(other_taggable)
        end

        it 'strips tags' do
          taggable.tag_list = ['       taga', 'tagb      ', '   tagc    ']

          service.insert!
          expect(taggable.tags.map(&:name)).to match_array(%w[taga tagb tagc])
        end

        context 'when batching inserts for tags' do
          before do
            stub_const("#{described_class}::TAGS_BATCH_SIZE", 2)
          end

          it 'inserts tags in batches' do
            recorder = ActiveRecord::QueryRecorder.new { service.insert! }
            count = recorder.log.count { |query| query.include?('INSERT INTO "tags"') }

            expect(count).to eq(2)
          end
        end

        context 'when batching inserts for taggings' do
          before do
            stub_const("#{described_class}::TAGGINGS_BATCH_SIZE", 2)
          end

          it 'inserts taggings in batches' do
            recorder = ActiveRecord::QueryRecorder.new { service.insert! }
            count = recorder.log.count { |query| query.include?("INSERT INTO \"#{tagging_class.table_name}\"") }

            expect(count).to eq(3)
          end
        end
      end

      context 'with tags for only one taggable' do
        before do
          taggable.tag_list = %w[tag1 tag2]
        end

        it 'persists tags' do
          expect(service.insert!).to be_truthy

          expect(taggable.reload.tag_list).to match_array(%w[tag1 tag2])
          expect(other_taggable.reload.tag_list).to be_empty
        end

        it 'persists taggings' do
          service.insert!

          expect(taggable.taggings.size).to eq(2)

          expect(taggable_class.tagged_with('tag1')).to include(taggable)
          expect(taggable_class.tagged_with('tag2')).to include(taggable)
        end
      end
    end
  end
end

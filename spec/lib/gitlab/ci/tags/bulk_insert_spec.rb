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
  let(:config) { described_class::NoConfig.new }

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
            count = recorder.log.count { |query| query.include?('INSERT INTO "taggings"') }

            expect(count).to eq(3)
          end
        end

        context 'with no config provided' do
          it 'does not persist tag links' do
            service.insert!

            expect(taggable.tag_links).to be_empty
            expect(other_taggable.tag_links).to be_empty
          end
        end

        context 'with config provided by the factory' do
          let(:config) { nil }

          it 'generates a valid config' do
            expect(service.config).to be_a(expected_configuration)
          end

          context 'with flags' do
            before do
              allow(service.config).to receive(:monomorphic_taggings?) { monomorphic_taggings }
              allow(service.config).to receive(:polymorphic_taggings?) { polymorphic_taggings }
            end

            context 'when writing to both tables' do
              let(:monomorphic_taggings) { true }
              let(:polymorphic_taggings) { true }

              it 'persists tag links and taggings' do
                service.insert!

                expect(taggable.tag_links).not_to be_empty
                expect(other_taggable.tag_links).not_to be_empty

                expect(tagged_with('tag1')).to contain_exactly(taggable)
                expect(tagged_with('tag2')).to contain_exactly(taggable, other_taggable)
                expect(tagged_with('tag3')).to contain_exactly(other_taggable)

                expect(taggable.taggings).not_to be_empty
                expect(other_taggable.taggings).not_to be_empty

                expect(taggable_class.tagged_with('tag1')).to contain_exactly(taggable)
                expect(taggable_class.tagged_with('tag2')).to contain_exactly(taggable, other_taggable)
                expect(taggable_class.tagged_with('tag3')).to contain_exactly(other_taggable)
              end
            end

            context 'when writing only to taggings' do
              let(:monomorphic_taggings) { false }
              let(:polymorphic_taggings) { true }

              it 'persists taggings' do
                service.insert!

                expect(taggable.tag_links).to be_empty
                expect(other_taggable.tag_links).to be_empty

                expect(taggable.taggings).not_to be_empty
                expect(other_taggable.taggings).not_to be_empty

                expect(taggable_class.tagged_with('tag1')).to contain_exactly(taggable)
                expect(taggable_class.tagged_with('tag2')).to contain_exactly(taggable, other_taggable)
                expect(taggable_class.tagged_with('tag3')).to contain_exactly(other_taggable)
              end
            end

            context 'when writing only to link table' do
              let(:monomorphic_taggings) { true }
              let(:polymorphic_taggings) { false }

              it 'persists tag links' do
                service.insert!

                expect(taggable.tag_links).not_to be_empty
                expect(other_taggable.tag_links).not_to be_empty

                expect(tagged_with('tag1')).to contain_exactly(taggable)
                expect(tagged_with('tag2')).to contain_exactly(taggable, other_taggable)
                expect(tagged_with('tag3')).to contain_exactly(other_taggable)

                expect(taggable.taggings).to be_empty
                expect(other_taggable.taggings).to be_empty
              end
            end

            def tagged_with(tag)
              scope = tagging_class
                .where(tag_id: Ci::Tag.where(name: tag))
                .where(tagging_class.arel_table[taggable_id_column].eq(taggable_class.arel_table[:id]))
                .where(tagging_class.arel_table[partition_column].eq(taggable_class.arel_table[partition_column]))

              taggable_class.where_exists(scope)
            end
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

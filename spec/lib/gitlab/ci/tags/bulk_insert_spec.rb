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

  where(:taggable_class, :taggable, :other_taggable, :join_model_class, :expected_configuration) do
    Ci::Build  | ref(:job)    | ref(:other_job)    | nil               | described_class::BuildsTagsConfiguration
    Ci::Runner | ref(:runner) | ref(:other_runner) | Ci::RunnerTagging | described_class::RunnerTaggingsConfiguration
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
      subject(:insert!) { service.insert! }

      it 'generates a valid config' do
        expect(service.config).to be_a(expected_configuration)
      end

      context 'without tags' do
        it { is_expected.to be_truthy }
      end

      context 'with tags' do
        let(:expected_taggings) { join_model_class ? 2 : 0 }
        let(:expected_other_taggings) { join_model_class ? 3 : 0 }

        before do
          set_tag_list(taggable, %w[tag1 tag2])
          set_tag_list(other_taggable, %w[tag2 tag3 tag4])
        end

        it 'persists tags' do
          expect(insert!).to be_truthy

          expect(taggable.reload.tag_list).to match_array(%w[tag1 tag2])
          expect(other_taggable.reload.tag_list).to match_array(%w[tag2 tag3 tag4])
        end

        it 'persists taggings for runners but not for builds' do
          insert!

          expect(taggable.taggings.size).to eq(expected_taggings)
          expect(other_taggable.taggings.size).to eq(expected_other_taggings)
        end

        context 'when ci_stop_populating_p_ci_build_tags feature flag is disabled' do
          before do
            stub_feature_flags(ci_stop_populating_p_ci_build_tags: false)
          end

          it 'persists tags' do
            expect(insert!).to be_truthy

            expect(taggable.reload.tag_list).to match_array(%w[tag1 tag2])
            expect(other_taggable.reload.tag_list).to match_array(%w[tag2 tag3 tag4])
          end

          it 'persists expected taggings' do
            insert!

            expect(taggable.taggings.size).to eq(2)
            expect(other_taggable.taggings.size).to eq(3)

            expect(taggable_class.tagged_with('tag1')).to include(taggable)
            expect(taggable_class.tagged_with('tag2')).to include(taggable, other_taggable)
            expect(taggable_class.tagged_with('tag3')).to include(other_taggable)
          end
        end

        context 'when tagging class has name column' do
          it 'sets names to tag names for runner taggings' do
            next unless join_model_class == Ci::RunnerTagging

            insert!

            taggable.taggings.each do |tagging|
              expect(tagging.tag_name).to eq(tagging.tag.name)
            end

            other_taggable.taggings.each do |tagging|
              expect(tagging.tag_name).to eq(tagging.tag.name)
            end
          end
        end

        context 'when tags have white-space' do
          let(:expected_tags) { %w[taga tagb tagc] }
          let(:expected_taggings) { join_model_class ? expected_tags : [] }

          before do
            set_tag_list(taggable, ['       taga', 'tagb      ', '   tagc    '])
          end

          it 'strips tags' do
            insert!

            expect(taggable.tag_list).to match_array(expected_tags)
            expect(taggable.tags.map(&:name)).to match_array(expected_taggings)
          end
        end

        context 'when batching inserts for tags' do
          before do
            stub_const("#{described_class}::TAGS_BATCH_SIZE", 2)
          end

          it 'inserts tags in batches' do
            next unless service.config.uses_taggings?

            recorder = ActiveRecord::QueryRecorder.new { insert! }
            count = recorder.log.count { |query| query.include?('INSERT INTO "tags"') }

            expect(count).to eq(2)
          end
        end

        context 'when batching inserts for taggings' do
          before do
            stub_const("#{described_class}::TAGGINGS_BATCH_SIZE", 2)
          end

          it 'inserts expected taggings in batches' do
            next if join_model_class.nil?

            recorder = ActiveRecord::QueryRecorder.new { insert! }
            count = recorder.log.count { |query| query.include?("INSERT INTO \"#{join_model_class.table_name}\"") }

            expect(count).to eq(3)
          end
        end
      end

      context 'with tags for only one taggable' do
        let(:expected_tagging_count) { join_model_class ? 2 : 0 }

        before do
          set_tag_list(taggable, %w[tag1 tag2])
        end

        it 'persists tags' do
          expect(insert!).to be_truthy

          expect(taggable.reload.tag_list).to match_array(%w[tag1 tag2])
          expect(other_taggable.reload.tag_list).to be_empty
        end

        it 'persists expected taggings' do
          insert!

          expect(taggable.taggings.size).to eq(expected_tagging_count)

          next if join_model_class.nil?

          expect(taggable_class.tagged_with('tag1')).to include(taggable)
          expect(taggable_class.tagged_with('tag2')).to include(taggable)
        end

        context 'when ci_stop_populating_p_ci_build_tags feature flag is disabled' do
          # With feature flag disabled, taggings are created for builds
          let(:expected_tagging_count) { taggable_class == Ci::Build || join_model_class ? 2 : 0 }

          before do
            stub_feature_flags(ci_stop_populating_p_ci_build_tags: false)
          end

          it 'persists expected taggings' do
            insert!

            expect(taggable.taggings.size).to eq(expected_tagging_count)
          end
        end
      end
    end

    private

    def set_tag_list(taggable, tags)
      return stub_ci_job_definition(taggable, tag_list: tags) if taggable_class == Ci::Build

      taggable.tag_list = tags
    end
  end
end

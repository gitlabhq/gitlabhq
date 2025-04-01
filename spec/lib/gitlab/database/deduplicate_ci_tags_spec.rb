# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DeduplicateCiTags, :aggregate_failures, feature_category: :runner do
  let(:logger) { instance_double(Logger) }
  let(:dry_run) { false }
  let(:service) { described_class.new(logger: logger, dry_run: dry_run) }

  # Set up the following structure:
  #   - runner1 tagged with `tag1`, `tag2` (#1)
  #   - runner2 tagged with `tag3`
  #   - build1 tagged with `tag1`
  #   - pending_build1 tagged with `tag1`
  let(:connection) { ::Ci::ApplicationRecord.connection }
  let(:partition_id) { 100 }
  let(:project_id) { 1 }
  let(:build1_id) { create_build }
  let!(:pending_build1_id) { create_pending_build(build1_id, [tag_ids.first]) }
  let(:runner1_id) { create_runner }
  let(:runner2_id) { create_runner }
  let(:tag_ids) { connection.select_values("INSERT INTO tags (name) VALUES ('tag1'), ('tag2'), ('tag3') RETURNING id") }

  let!(:ci_runner_tagging_ids) do
    connection.select_values(<<~SQL)
      INSERT INTO ci_runner_taggings (runner_id, tag_id, runner_type)
        VALUES (#{runner1_id}, #{tag_ids.first}, 1),
               (#{runner1_id}, #{tag_ids.second}, 1),
               (#{runner2_id}, #{tag_ids.third}, 1)
      RETURNING id;
    SQL
  end

  let!(:ci_build_tagging_ids) do
    connection.select_values(<<~SQL)
      INSERT INTO p_ci_build_tags (build_id, tag_id, partition_id, project_id)
        VALUES (#{build1_id}, #{tag_ids.second}, #{partition_id}, #{project_id})
      RETURNING id;
    SQL
  end

  let(:tagging_ids) do
    [
      ci_build_tagging_ids, ci_runner_tagging_ids
    ]
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    before do
      allow(logger).to receive(:info)
    end

    it 'does not change number of tags or taggings tag_ids' do
      expect { execute }.to not_change { table_count('tags') }
        .and not_change { ci_pending_build_tag_ids_for(pending_build1_id) }
        .and not_change { ci_runner_tagging_relationship_for(ci_runner_tagging_ids.second) }
        .and not_change { ci_runner_tagging_relationship_for(ci_runner_tagging_ids.third) }

      expect(logger).to have_received(:info).with('No duplicate tags found in ci database')
    end

    context 'when duplicate tags exist' do
      # Set up the following structure:
      #   - runner1 tagged with `tag1`, `tag2` (#1)
      #   - runner2 tagged with `tag3`, `tag2` (#2)
      #   - build1 tagged with `tag2` (#1)
      #   - build2 tagged with `tag2` (#3), `tag3`
      #   - pending_build2 tagged with `tag2` (#3), `tag3`
      let(:duplicate_tag_ids) do
        connection.select_values("INSERT INTO tags (name) VALUES ('tag2'), ('tag2') RETURNING id")
      end

      let(:build2_id) { create_build }
      let(:pending_build2_id) { create_pending_build(build2_id, [duplicate_tag_ids.second, tag_ids.third]) }

      let!(:ci_build2_tagging1_id) do
        connection.select_value(<<~SQL)
          INSERT INTO p_ci_build_tags (build_id, tag_id, partition_id, project_id)
            VALUES (#{build2_id}, #{tag_ids.second}, #{partition_id}, #{project_id}) RETURNING id;
        SQL
      end

      let!(:duplicate_ci_build2_tagging2_id) do
        connection.select_value(<<~SQL)
          INSERT INTO p_ci_build_tags (build_id, tag_id, partition_id, project_id)
            VALUES (#{build2_id}, #{duplicate_tag_ids.second}, #{partition_id}, #{project_id}) RETURNING id;
        SQL
      end

      let!(:duplicate_ci_build2_tagging3_id) do
        connection.select_value(<<~SQL)
          INSERT INTO p_ci_build_tags (build_id, tag_id, partition_id, project_id)
            VALUES (#{build2_id}, #{duplicate_tag_ids.second}, #{partition_id}, #{project_id}) RETURNING id;
        SQL
      end

      let(:duplicate_ci_runner_tagging_id) do
        connection.select_value(<<~SQL)
          INSERT INTO ci_runner_taggings (runner_id, tag_id, runner_type)
            VALUES (#{runner2_id}, #{duplicate_tag_ids.first}, 1) RETURNING id
        SQL
      end

      let(:duplicate_tagging_ids) do
        [
          ci_build2_tagging1_id, duplicate_ci_build2_tagging2_id, duplicate_ci_runner_tagging_id,
          pending_build2_id
        ]
      end

      around do |example|
        connection.transaction do
          tagging_ids

          # allow a scenario where multiple tags with same name coexist
          connection.execute('DROP INDEX index_tags_on_name')
          # allow a scenario where same build with same tag id coexist
          connection.execute('DROP INDEX index_p_ci_build_tags_on_tag_id_and_build_id_and_partition_id')

          duplicate_tagging_ids

          example.run
        end
      end

      it 'deletes duplicate tags and updates taggings' do
        expect { execute }
          .to change { table_count('tags') }.by(-2)
          .and not_change { ci_runner_tagging_relationship_for(ci_runner_tagging_ids.second) }
          .and not_change { ci_pending_build_tag_ids_for(pending_build1_id) }
          .and not_change { ci_build_tagging_relationship_for(ci_build2_tagging1_id) }
            .from(build2_id => tag_ids.second)
          .and change { ci_build_tagging_relationship_for(duplicate_ci_build2_tagging2_id) }
            .from(build2_id => duplicate_tag_ids.second)
            .to({})
          .and change { ci_build_tagging_relationship_for(duplicate_ci_build2_tagging3_id) }
            .from(build2_id => duplicate_tag_ids.second)
            .to({})
          .and change { ci_pending_build_tag_ids_for(pending_build2_id) }
            .from([duplicate_tag_ids.second, tag_ids.third])
            .to([tag_ids.second, tag_ids.third])
          .and change { ci_runner_tagging_relationship_for(duplicate_ci_runner_tagging_id) }
            .from(runner2_id => duplicate_tag_ids.first)
            .to(runner2_id => tag_ids.second)

        # Index was recreated
        expect(index_exists?('index_tags_on_name')).to be true

        expect(logger).to have_received(:info).with('Deduplicating 2 tags for ci database')
        expect(logger).to have_received(:info).with('Done')
      end

      context 'and dry_run is true' do
        let(:dry_run) { true }

        it 'does not change number of tags or taggings tag_ids' do
          expect { execute }.to not_change { table_count('tags') }
            .and not_change { ci_runner_tagging_relationship_for(ci_runner_tagging_ids.second) }
            .and not_change { ci_runner_tagging_relationship_for(ci_runner_tagging_ids.third) }
            .and not_change { ci_pending_build_tag_ids_for(pending_build2_id) }
            .and not_change { ci_build_tagging_relationship_for(duplicate_ci_build2_tagging2_id) }
            .and not_change { ci_runner_tagging_relationship_for(duplicate_ci_runner_tagging_id) }

          # Index wasn't recreated because we're in dry run mode
          expect(index_exists?('index_tags_on_name')).to be false

          expect(logger).to have_received(:info).with('DRY RUN:')
          expect(logger).to have_received(:info).with('Deduplicating 2 tags for ci database')
          expect(logger).to have_received(:info).with('Done')
        end
      end
    end
  end

  private

  def create_runner
    connection.select_value("INSERT INTO ci_runners (runner_type) VALUES (#{project_id}) RETURNING id")
  end

  def create_build
    connection.select_value(<<~SQL)
      INSERT INTO p_ci_builds (partition_id, project_id) VALUES (#{partition_id}, #{project_id}) RETURNING id
    SQL
  end

  def create_pending_build(build_id, tag_ids)
    connection.select_value(<<~SQL)
      INSERT INTO ci_pending_builds (build_id, tag_ids, partition_id, project_id)
        VALUES (#{build_id}, ARRAY#{tag_ids}, #{partition_id}, #{project_id}) RETURNING id
    SQL
  end

  def table_count(table_name)
    connection.select_value("SELECT COUNT(*) FROM #{table_name}")
  end

  def index_exists?(index_name)
    connection.select_value(<<-SQL).present?
      SELECT 1 FROM pg_class WHERE relname = '#{index_name}'
    SQL
  end

  def ci_pending_build_tag_ids_for(pending_build_id)
    connection.select_value("SELECT tag_ids FROM ci_pending_builds WHERE id = #{pending_build_id}")
      .tr('{}', '').split(',').map(&:to_i)
  end

  def ci_build_tagging_relationship_for(tagging_id)
    connection.execute("SELECT build_id, tag_id FROM p_ci_build_tags WHERE id = #{tagging_id}").values.to_h
  end

  def ci_runner_tagging_relationship_for(tagging_id)
    connection.execute("SELECT runner_id, tag_id FROM ci_runner_taggings WHERE id = #{tagging_id}").values.to_h
  end
end

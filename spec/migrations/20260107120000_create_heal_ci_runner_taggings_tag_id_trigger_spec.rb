# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateHealCiRunnerTaggingsTagIdTrigger, feature_category: :runner_core do
  let(:tags) { table(:tags, database: :ci, primary_key: :id) }
  let(:runners) { table(:ci_runners, database: :ci, primary_key: :id) }
  let(:runner_taggings) { table(:ci_runner_taggings, database: :ci, primary_key: :id) }

  before do
    migrate!
  end

  describe 'trigger function' do
    let(:runner) { runners.create!(runner_type: 1) }
    let(:tagging) do
      runner_taggings.create!(
        runner_id: runner.id,
        runner_type: runner.runner_type,
        tag_name: tag_name,
        tag_id: tag_id
      )
    end

    context 'when inserting with NULL tag_id and valid tag_name' do
      let(:tag_name) { 'docker' }
      let(:tag_id) { nil }

      it 'creates a tag and populates tag_id' do
        expect(tagging.reload.tag_id).not_to be_nil
        expect(tags.find(tagging.tag_id).name).to eq(tag_name)
      end

      context 'with existing tag' do
        let(:tag_name) { 'kubernetes' }
        let!(:existing_tag) { tags.create!(name: tag_name) }

        it 'reuses existing tag with same name' do
          expect(tagging.reload.tag_id).to eq(existing_tag.id)
        end
      end

      context 'with multiple runners' do
        let(:tag_name) { 'linux' }
        let(:runner2) { runners.create!(runner_type: 1) }
        let(:tagging2) do
          runner_taggings.create!(
            runner_id: runner2.id,
            runner_type: runner2.runner_type,
            tag_name: tag_name,
            tag_id: nil
          )
        end

        it 'deduplicates tags with same name' do
          expect(tagging.reload.tag_id).to eq(tagging2.reload.tag_id)
          expect(tags.where(name: tag_name).count).to eq(1)
        end
      end
    end

    context 'when inserting with non-existent tag_id and NULL tag_name' do
      let(:tag_id) { non_existing_record_id }
      let(:tag_name) { nil }

      it 'raises error' do
        expect { tagging }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end

    context 'when inserting with both NULL' do
      let(:tag_id) { nil }
      let(:tag_name) { nil }

      it 'raises error' do
        expect { tagging }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end

    context 'when inserting with both provided' do
      let(:tag_name) { 'macos' }
      let(:tag) { tags.create!(name: tag_name) }
      let(:tag_id) { tag.id }

      it 'accepts the values' do
        expect(tagging.reload.tag_id).to eq(tag.id)
        expect(tagging.reload.tag_name).to eq(tag_name)
      end
    end
  end
end

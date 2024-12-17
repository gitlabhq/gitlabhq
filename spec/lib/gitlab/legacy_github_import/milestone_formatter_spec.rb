# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::MilestoneFormatter do
  let_it_be(:project) { create(:project, :with_import_url, :import_user_mapping_enabled) }

  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
  let(:base_data) do
    {
      state: 'open',
      title: '1.0',
      description: 'Version 1.0',
      due_on: nil,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil
    }
  end

  let(:iid_attr) { :number }

  subject(:milestone) { described_class.new(project, raw_data) }

  describe '#attributes' do
    shared_examples 'Gitlab::LegacyGithubImport::MilestoneFormatter#attributes' do
      let(:data) { base_data.merge(iid_attr => 1347) }

      context 'when milestone is open' do
        let(:raw_data) { data.merge(state: 'open') }

        it 'returns formatted attributes' do
          expected = {
            iid: 1347,
            project: project,
            title: '1.0',
            description: 'Version 1.0',
            state: 'active',
            due_date: nil,
            created_at: created_at,
            updated_at: updated_at
          }

          expect(milestone.attributes).to eq(expected)
        end
      end

      context 'when milestone is closed' do
        let(:raw_data) { data.merge(state: 'closed') }

        it 'returns formatted attributes' do
          expected = {
            iid: 1347,
            project: project,
            title: '1.0',
            description: 'Version 1.0',
            state: 'closed',
            due_date: nil,
            created_at: created_at,
            updated_at: updated_at
          }

          expect(milestone.attributes).to eq(expected)
        end
      end

      context 'when milestone has a due date' do
        let(:due_date) { DateTime.strptime('2011-01-28T19:01:12Z') }
        let(:raw_data) { data.merge(due_on: due_date) }

        it 'returns formatted attributes' do
          expected = {
            iid: 1347,
            project: project,
            title: '1.0',
            description: 'Version 1.0',
            state: 'active',
            due_date: due_date,
            created_at: created_at,
            updated_at: updated_at
          }

          expect(milestone.attributes).to eq(expected)
        end
      end

      context 'when milestone has @mentions in description' do
        let(:original_desc) { "I said to @sam_allen.greg code should follow @bob's advice. @.ali-ce/group#9?" }
        let(:expected_desc) { "I said to `@sam_allen.greg` code should follow `@bob`'s advice. `@.ali-ce/group#9`?" }
        let(:raw_data) { data.merge(description: original_desc) }

        it 'inserts backticks around usernames' do
          expect(milestone.attributes[:description]).to eq(expected_desc)
        end
      end
    end

    context 'when importing a GitHub project' do
      it_behaves_like 'Gitlab::LegacyGithubImport::MilestoneFormatter#attributes'
    end

    context 'when importing a Gitea project' do
      let(:iid_attr) { :id }

      before do
        project.update!(import_type: 'gitea')
      end

      it_behaves_like 'Gitlab::LegacyGithubImport::MilestoneFormatter#attributes'
    end
  end

  describe '#contributing_user_formatters' do
    let(:raw_data) { base_data }

    it { expect(milestone.contributing_user_formatters).to eq({}) }

    it 'includes all user reference columns in #attributes' do
      expect(milestone.contributing_user_formatters.keys).to match_array(
        milestone.attributes.keys & Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES.map(&:to_sym)
      )
    end
  end

  describe '#create!', :aggregate_failures, :clean_gitlab_redis_shared_state do
    let(:raw_data) { base_data }
    let(:store) { project.placeholder_reference_store }

    it 'creates the milestone' do
      expect { milestone.create! }.to change { project.milestones.count }.from(0).to(1)
    end

    it 'does not push any placeholder references because it does not reference a user' do
      milestone_user_refs = milestone.attributes.keys & Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES
      milestone.create!

      expect(store.empty?).to be(true)
      expect(milestone_user_refs).to be_empty
    end
  end
end

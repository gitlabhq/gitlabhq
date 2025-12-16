# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderReferences::Pusher, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be(:group) { create(:group) }
  let_it_be(:group_project) { create(:project, namespace: group, import_type: 'github') }

  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:personal_project) { create(:project, namespace: user.namespace, import_type: 'github') }

  let(:project) { group_project }

  let(:reassign_user) { create(:user) }
  let(:record) { create(:note, project: project) }
  let(:attribute) { :author_id }
  let(:user_mapping_enabled) { true }
  let(:cached_references) { placeholder_user_references('github', import_state.id) }

  let!(:import_state) { create(:import_state, project: project) }

  let!(:import_source_user) do
    create(:import_source_user, :awaiting_approval,
      namespace: project.namespace,
      placeholder_user: create(:user, :import_user))
  end

  let!(:placeholder_source_user) do
    create(:import_source_user, :awaiting_approval,
      namespace: project.namespace,
      placeholder_user: create(:user, :placeholder))
  end

  let!(:mapped_source_user) do
    create(:import_source_user, :completed,
      namespace: project.namespace,
      reassign_to_user: reassign_user)
  end

  let(:import_source_user_identifier) { import_source_user.source_user_identifier }
  let(:placeholder_source_user_identifier) { placeholder_source_user.source_user_identifier }
  let(:mapped_source_user_identifier) { mapped_source_user.source_user_identifier }

  let(:store) { Import::PlaceholderReferences::Store.new(import_source: :github, import_uid: import_state.id) }

  let(:test_class) do
    Class.new do
      include Import::PlaceholderReferences::Pusher

      attr_reader :project

      def initialize(project)
        @project = project
      end
    end
  end

  subject(:pusher) { test_class.new(project) }

  before do
    project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: user_mapping_enabled })
    project.import_data.save!

    allow(project).to receive(:safe_import_url).and_return('https://github.com/example/repo')
  end

  describe '#push_reference' do
    it 'creates a placeholder reference in the store' do
      expect { pusher.push_reference(project, record, attribute, import_source_user_identifier) }
        .to change { store.count }.by(1)
    end

    it 'stores the correct reference data' do
      pusher.push_reference(project, record, attribute, import_source_user_identifier)

      expect(cached_references).to contain_exactly(
        ['Note', record.id, 'author_id', import_source_user.id]
      )
    end

    context 'when source_user_identifier is blank' do
      it 'does not create a placeholder reference' do
        expect { pusher.push_reference(project, record, attribute, nil) }.not_to change { store.count }
      end
    end

    context 'when user mapping is disabled' do
      let(:user_mapping_enabled) { false }

      it 'does not create a placeholder reference' do
        expect { pusher.push_reference(project, record, attribute, import_source_user_identifier) }
          .not_to change { store.count }
      end
    end

    context 'when project is in a personal namespace' do
      let(:project) { personal_project }

      it 'does not create a placeholder reference' do
        expect { pusher.push_reference(project, record, attribute, import_source_user_identifier) }
          .not_to change { store.count }
      end
    end

    context 'when source_user is nil' do
      it 'does not create a placeholder reference' do
        expect { pusher.push_reference(project, record, attribute, 99999) }.not_to change { store.count }
      end
    end

    context 'when source_user is accepted' do
      it 'does not create a placeholder reference' do
        expect { pusher.push_reference(project, record, attribute, mapped_source_user_identifier) }
          .not_to change { store.count }
      end
    end

    context 'when source_user is associated to a placeholder user type' do
      it 'does not create a placeholder reference' do
        expect { pusher.push_reference(project, record, attribute, placeholder_source_user_identifier) }
          .not_to change { store.count }
      end

      context 'when record attribute does not support direct reassignment' do
        it 'creates a placeholder reference in the store' do
          expect { pusher.push_reference(project, record, :updated_by_id, placeholder_source_user_identifier) }
            .to change { store.count }.by(1)
        end

        it 'stores the correct reference data' do
          pusher.push_reference(project, record, :updated_by_id, placeholder_source_user_identifier)

          expect(cached_references).to contain_exactly(
            ['Note', record.id, 'updated_by_id', placeholder_source_user.id]
          )
        end
      end
    end
  end

  describe '#push_references_by_ids' do
    let(:note1) { create(:note, project: project) }
    let(:note2) { create(:note, project: project) }
    let(:note3) { create(:note, project: project) }
    let(:ids) { [note1.id, note2.id, note3.id] }
    let(:model) { Note }

    it 'creates placeholder references for each id' do
      expect { pusher.push_references_by_ids(project, ids, model, attribute, import_source_user_identifier) }
        .to change { store.count }.by(3)
    end

    it 'stores the correct reference data for each id' do
      pusher.push_references_by_ids(project, ids, model, attribute, import_source_user_identifier)

      expect(cached_references).to contain_exactly(
        ["Note", note1.id, "author_id", import_source_user.id],
        ["Note", note2.id, "author_id", import_source_user.id],
        ["Note", note3.id, "author_id", import_source_user.id]
      )
    end

    context 'when source_user is nil' do
      it 'does not create placeholder references' do
        expect { pusher.push_references_by_ids(project, ids, model, attribute, 99999) }.not_to change { store.count }
      end
    end

    context 'when source_user has accepted status' do
      it 'does not create placeholder references' do
        expect { pusher.push_references_by_ids(project, ids, model, attribute, mapped_source_user_identifier) }
          .not_to change { store.count }
      end
    end

    context 'when source_user is associated to a placeholder user type' do
      it 'does not create a placeholder reference' do
        expect { pusher.push_references_by_ids(project, ids, model, attribute, placeholder_source_user_identifier) }
          .not_to change { store.count }
      end

      context 'when record attribute does not support direct reassignment' do
        it 'creates a placeholder reference in the store' do
          expect do
            pusher.push_references_by_ids(project, ids, model, :updated_by_id, placeholder_source_user_identifier)
          end.to change { store.count }.by(3)
        end

        it 'stores the correct reference data' do
          pusher.push_references_by_ids(project, ids, model, :updated_by_id,
            placeholder_source_user_identifier)

          expect(cached_references).to contain_exactly(
            ["Note", note1.id, "updated_by_id", placeholder_source_user.id],
            ["Note", note2.id, "updated_by_id", placeholder_source_user.id],
            ["Note", note3.id, "updated_by_id", placeholder_source_user.id]
          )
        end
      end
    end
  end

  describe '#push_reference_with_composite_key' do
    let(:issue) { create(:issue, project: project) }
    let(:issue_assignee) { create(:issue_assignee, issue: issue) }
    let(:composite_key) { { 'user_id' => issue_assignee.user_id, 'issue_id' => issue_assignee.issue_id } }

    it 'creates a placeholder reference with composite key' do
      expect do
        pusher.push_reference_with_composite_key(project, issue_assignee, :user_id, composite_key,
          import_source_user_identifier)
      end.to change { store.count }.by(1)
    end

    it 'stores the correct reference data with composite key' do
      pusher.push_reference_with_composite_key(project, issue_assignee, :user_id, composite_key,
        import_source_user_identifier)

      expect(cached_references).to contain_exactly(
        [
          'IssueAssignee',
          { 'user_id' => issue_assignee.user_id, 'issue_id' => issue.id },
          'user_id', import_source_user.id
        ]
      )
    end

    context 'when source_user is nil' do
      it 'does not create a placeholder reference' do
        expect { pusher.push_reference_with_composite_key(project, issue_assignee, :user_id, composite_key, 99999) }
          .not_to change { store.count }
      end
    end

    context 'when project is in a personal namespace' do
      let(:project) { personal_project }

      it 'does not create a placeholder reference' do
        expect do
          pusher.push_reference_with_composite_key(project, issue_assignee, :user_id, composite_key,
            import_source_user_identifier)
        end.not_to change { store.count }
      end
    end

    context 'when source_user is accepted and mapped to the record' do
      it 'does not create a placeholder reference' do
        expect do
          pusher.push_reference_with_composite_key(project, issue_assignee, :user_id, composite_key,
            mapped_source_user_identifier)
        end.not_to change { store.count }
      end
    end
  end

  describe '#user_mapping_enabled?' do
    context 'when user mapping is enabled' do
      let(:user_mapping_enabled) { true }

      it 'returns true' do
        expect(pusher.user_mapping_enabled?(project)).to be true
      end
    end

    context 'when user mapping is disabled' do
      let(:user_mapping_enabled) { false }

      it 'returns false' do
        expect(pusher.user_mapping_enabled?(project)).to be false
      end
    end
  end

  describe '#map_to_personal_namespace_owner?' do
    context 'when project is in a group namespace' do
      let(:project) { group_project }

      it 'returns false' do
        expect(pusher.map_to_personal_namespace_owner?(project)).to be false
      end
    end

    context 'when project is in a personal namespace' do
      let(:project) { personal_project }

      it 'returns true' do
        expect(pusher.map_to_personal_namespace_owner?(project)).to be true
      end
    end
  end
end

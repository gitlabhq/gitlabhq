# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Base::RelationFactory, feature_category: :importers do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:members_mapper) { double('members_mapper').as_null_object }
  let(:relation_sym) { :project_snippets }
  let(:relation_hash) { {} }
  let(:excluded_keys) { [] }
  let(:import_source) { Import::SOURCE_DIRECT_TRANSFER }
  let(:original_users_map) { nil }

  let(:relation_factory) do
    described_class.new(
      relation_sym: relation_sym,
      relation_hash: relation_hash,
      relation_index: 1,
      object_builder: Gitlab::ImportExport::Project::ObjectBuilder,
      members_mapper: members_mapper,
      user: user,
      importable: project,
      import_source: import_source,
      original_users_map: original_users_map
    )
  end

  describe '#create' do
    subject { relation_factory.create } # rubocop:disable Rails/SaveBang -- this is a factory

    context 'when relation is invalid' do
      before do
        expect_next_instance_of(described_class) do |relation_factory|
          expect(relation_factory).to receive(:invalid_relation?).and_return(true)
        end
      end

      it 'returns without creating new relations' do
        expect(subject).to be_nil
      end
    end

    context 'when the relation is predefined' do
      let(:relation_sym) { :milestone }
      let(:relation_hash) { { 'name' => '#upcoming', 'title' => 'Upcoming', 'id' => -2 } }

      it 'returns without creating a new relation' do
        expect(subject).to be_nil
      end
    end

    context 'when author relation' do
      let(:relation_sym) { :author }
      let(:relation_hash) { { 'name' => 'User', 'project_id' => project.id } }

      it 'returns author hash unchanged' do
        expect(subject).to eq(relation_hash)
      end
    end

    context 'when #setup_models is not implemented' do
      it 'raises NotImplementedError' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end

    context 'when #setup_models is implemented' do
      let(:relation_sym) { :notes }
      let(:relation_hash) do
        {
          "id" => 4947,
          "note" => "merged",
          "noteable_type" => "MergeRequest",
          "author_id" => 999,
          "created_at" => "2016-11-18T09:29:42.634Z",
          "updated_at" => "2016-11-18T09:29:42.634Z",
          "project_id" => 1,
          "attachment" => {
            "url" => nil
          },
          "noteable_id" => 377,
          "system" => true,
          "events" => []
        }
      end

      before do
        expect_next_instance_of(described_class) do |relation_factory|
          expect(relation_factory).to receive(:setup_models).and_return(true)
        end
      end

      it 'creates imported object' do
        expect(subject).to be_instance_of(Note)
      end

      it 'sets imported_from' do
        expect(subject.imported_from).to eq(Import::SOURCE_DIRECT_TRANSFER.to_s)
      end

      context 'when import_source is gitlab_project' do
        let(:import_source) { Import::SOURCE_PROJECT_EXPORT_IMPORT }

        it 'sets imported_from' do
          expect(subject.imported_from).to eq(Import::SOURCE_PROJECT_EXPORT_IMPORT.to_s)
        end
      end

      context 'when object does not have an imported_from attribute' do
        let(:relation_sym) { :user }
        let(:relation_hash) { attributes_for(:user) }

        it 'works without an error' do
          expect(subject).not_to respond_to(:imported_from) # Sanity check: This must be true for test subject
          expect(subject).to be_instance_of(User)
        end
      end

      context 'when relation contains user references' do
        let(:new_user) { create(:user) }
        let(:exported_member) do
          {
            "id" => 111,
            "access_level" => 30,
            "source_id" => 1,
            "source_type" => "Project",
            "user_id" => 3,
            "notification_level" => 3,
            "created_at" => "2016-11-18T09:29:42.634Z",
            "updated_at" => "2016-11-18T09:29:42.634Z",
            "user" => {
              "id" => 999,
              "public_email" => new_user.email,
              "username" => new_user.username
            }
          }
        end

        let(:members_mapper) do
          Gitlab::ImportExport::MembersMapper.new(
            exported_members: [exported_member],
            user: user,
            importable: project)
        end

        it 'maps the right author to the imported note' do
          expect(subject.author).to eq(new_user)
        end

        context 'when original_users_map is nil' do
          it 'does not store the object original users' do
            subject

            expect(original_users_map).to eq(nil)
          end
        end

        context 'when original_users_map is a Hash' do
          let(:original_users_map) { {} }

          it "store the relation hash original user IDs" do
            subject

            expect(original_users_map[subject]).to eq({ 'author_id' => 999 })
          end
        end
      end

      context 'when relation contains token attributes' do
        let(:relation_sym) { 'ProjectHook' }
        let(:relation_hash) { { token: 'secret' } }

        it 'removes token attributes' do
          expect(subject.token).to be_nil
        end
      end

      context 'when relation contains encrypted attributes' do
        let(:relation_sym) { 'Ci::Variable' }
        let(:relation_hash) do
          create(:ci_variable).as_json
        end

        it 'removes encrypted attributes' do
          expect(subject.value).to be_nil
        end
      end

      context 'with duplicate assignees' do
        let(:relation_sym) { :issues }
        let(:relation_hash) do
          { "title" => "title", "state" => "opened" }.merge(issue_assignees)
        end

        context 'when duplicate assignees are present' do
          let(:issue_assignees) do
            {
              "issue_assignees" => [
                IssueAssignee.new(user_id: 1),
                IssueAssignee.new(user_id: 2),
                IssueAssignee.new(user_id: 1),
                { user_id: 3 }
              ]
            }
          end

          it 'removes duplicate assignees' do
            expect(subject.issue_assignees.map(&:user_id)).to contain_exactly(1, 2)
          end
        end
      end
    end
  end

  describe '.relation_class' do
    context 'when relation name is pluralized' do
      let(:relation_name) { 'MergeRequest::Metrics' }

      it 'returns constantized class' do
        expect(described_class.relation_class(relation_name)).to eq(MergeRequest::Metrics)
      end
    end

    context 'when relation name is singularized' do
      let(:relation_name) { 'Badge' }

      it 'returns constantized class' do
        expect(described_class.relation_class(relation_name)).to eq(Badge)
      end
    end

    context 'when relation name is user_contributions' do
      let(:relation_name) { 'user_contributions' }

      it 'returns constantized class' do
        expect(described_class.relation_class(relation_name)).to eq(User)
      end
    end
  end

  describe '#setup_note' do
    let(:relation_sym) { :notes }

    context 'when note is a merge request note' do
      let(:relation_hash) do
        {
          'id' => 1,
          'note' => "merged\n\n[Compare with previous version](/link)",
          'noteable_type' => 'MergeRequest',
          'noteable_id' => 1,
          'author_id' => 1,
          'created_at' => '2020-01-01T00:00:00Z',
          'updated_at' => '2020-01-01T00:00:00Z',
          'project_id' => project.id,
          'attachment' => nil,
          'system' => true
        }
      end

      it 'removes the compare link' do
        relation_factory.send(:setup_note)
        expect(relation_factory.relation_hash['note']).to eq('merged')
      end

      it 'removes attachment' do
        relation_factory.send(:setup_note)
        expect(relation_factory.relation_hash['attachment']).to be_nil
      end
    end

    context 'when note is not a merge request note' do
      let(:relation_hash) do
        {
          'id' => 1,
          'note' => "comment\n\n[Compare with previous version](/link)",
          'noteable_type' => 'Issue',
          'noteable_id' => 1,
          'author_id' => 1,
          'created_at' => '2020-01-01T00:00:00Z',
          'updated_at' => '2020-01-01T00:00:00Z',
          'project_id' => project.id,
          'attachment' => nil,
          'system' => true
        }
      end

      it 'does not remove the compare link' do
        relation_factory.send(:setup_note)
        expect(relation_factory.relation_hash['note']).to include('[Compare with previous version]')
      end

      it 'removes attachment' do
        relation_factory.send(:setup_note)
        expect(relation_factory.relation_hash['attachment']).to be_nil
      end
    end

    context 'when note is not a system note' do
      let(:relation_hash) do
        {
          'id' => 1,
          'note' => "comment\n\n[Compare with previous version](/link)",
          'noteable_type' => 'MergeRequest',
          'noteable_id' => 1,
          'author_id' => 1,
          'created_at' => '2020-01-01T00:00:00Z',
          'updated_at' => '2020-01-01T00:00:00Z',
          'project_id' => project.id,
          'attachment' => nil,
          'system' => false
        }
      end

      it 'does not remove the compare link' do
        relation_factory.send(:setup_note)
        expect(relation_factory.relation_hash['note']).to include('[Compare with previous version]')
      end

      it 'removes attachment' do
        relation_factory.send(:setup_note)
        expect(relation_factory.relation_hash['attachment']).to be_nil
      end
    end

    context 'when merge request note has blank content' do
      let(:relation_hash) do
        {
          'id' => 1,
          'note' => nil,
          'noteable_type' => 'MergeRequest',
          'noteable_id' => 1,
          'author_id' => 1,
          'created_at' => '2020-01-01T00:00:00Z',
          'updated_at' => '2020-01-01T00:00:00Z',
          'project_id' => project.id,
          'attachment' => nil,
          'system' => true
        }
      end

      it 'does not process the note' do
        relation_factory.send(:setup_note)
        expect(relation_factory.relation_hash['note']).to be_nil
      end
    end
  end

  describe '#setup_merge_request_note' do
    let(:relation_sym) { :notes }

    context 'when note is a merge request note with compare link' do
      let(:relation_hash) do
        {
          'note' => "text\n\n[Compare with previous version](/link)",
          'noteable_type' => 'MergeRequest',
          'system' => true
        }
      end

      it 'removes the compare link' do
        relation_factory.send(:setup_merge_request_note)
        expect(relation_factory.relation_hash['note']).to eq('text')
      end
    end

    context 'when note is not a merge request note' do
      let(:relation_hash) do
        {
          'note' => "text\n\n[Compare with previous version](/link)",
          'noteable_type' => 'Issue',
          'system' => true
        }
      end

      it 'does not remove the compare link' do
        relation_factory.send(:setup_merge_request_note)
        expect(relation_factory.relation_hash['note']).to include('[Compare with previous version]')
      end
    end

    context 'when note is blank' do
      let(:relation_hash) do
        {
          'note' => nil,
          'noteable_type' => 'MergeRequest',
          'system' => true
        }
      end

      it 'does not process the note' do
        relation_factory.send(:setup_merge_request_note)
        expect(relation_factory.relation_hash['note']).to be_nil
      end
    end

    context 'when noteable_type is missing' do
      let(:relation_hash) do
        {
          'note' => "text\n\n[Compare with previous version](/link)",
          'system' => true
        }
      end

      it 'does not remove the compare link' do
        relation_factory.send(:setup_merge_request_note)
        expect(relation_factory.relation_hash['note']).to include('[Compare with previous version]')
      end
    end
  end

  describe '#remove_compare_link' do
    context 'when content contains the compare link' do
      let(:content) do
        "merged\n\n[Compare with previous version](/link/-/merge_requests/1/diffs?diff_id=123)"
      end

      it 'removes the link' do
        result = relation_factory.send(:remove_compare_link, content)
        expect(result).to eq('merged')
      end
    end

    context 'when content does not contain the compare link' do
      let(:content) { 'Just a regular note' }

      it 'returns the content unchanged' do
        result = relation_factory.send(:remove_compare_link, content)
        expect(result).to eq(content)
      end
    end

    context 'when URL in link exceeds 1000 characters' do
      let(:long_url) { 'a' * 1001 }
      let(:content) { "[Compare with previous version](#{long_url})" }

      it 'does not remove the link due to URL length limit' do
        result = relation_factory.send(:remove_compare_link, content)
        expect(result).to eq(content)
      end
    end

    context 'when URL in link is within 1000 characters' do
      let(:long_url) { 'a' * 1000 }
      let(:content) { "\n\n[Compare with previous version](#{long_url})\n\n" }

      it 'removes the link' do
        result = relation_factory.send(:remove_compare_link, content)
        expect(result).to eq('')
      end
    end
  end
end

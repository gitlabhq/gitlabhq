# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Group::LegacyTreeSaver do
  describe 'saves the group tree into a json object' do
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:group_tree_saver) { described_class.new(group: group, current_user: user, shared: shared) }
    let(:export_path) { "#{Dir.tmpdir}/group_tree_saver_spec" }
    let(:user) { create(:user) }
    let!(:group) { setup_group }

    before do
      group.add_maintainer(user)
      allow(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves group successfully' do
      expect(group_tree_saver.save).to be true
    end

    # It is mostly duplicated in
    # `spec/lib/gitlab/import_export/fast_hash_serializer_spec.rb`
    # except:
    # context 'with description override' do
    # context 'group members' do
    # ^ These are specific for the Group::LegacyTreeSaver
    context 'JSON' do
      let(:saved_group_json) do
        group_tree_saver.save
        group_json(group_tree_saver.full_path)
      end

      it 'saves the correct json' do
        expect(saved_group_json).to include({ 'description' => 'description' })
      end

      it 'has milestones' do
        expect(saved_group_json['milestones']).not_to be_empty
      end

      it 'has labels' do
        expect(saved_group_json['labels']).not_to be_empty
      end

      it 'has boards' do
        expect(saved_group_json['boards']).not_to be_empty
      end

      it 'has board label list' do
        expect(saved_group_json['boards'].first['lists']).not_to be_empty
      end

      it 'has group members' do
        expect(saved_group_json['members']).not_to be_empty
      end

      it 'has priorities associated to labels' do
        expect(saved_group_json['labels'].first['priorities']).not_to be_empty
      end

      it 'has badges' do
        expect(saved_group_json['badges']).not_to be_empty
      end

      context 'group children' do
        let(:children) { group.children }

        it 'exports group children' do
          expect(saved_group_json['children'].length).to eq(children.count)
        end

        it 'exports group children of children' do
          expect(saved_group_json['children'].first['children'].length).to eq(children.first.children.count)
        end
      end

      context 'group members' do
        let(:user2) { create(:user, email: 'group@member.com') }
        let(:member_emails) do
          saved_group_json['members'].map do |pm|
            pm['user']['email']
          end
        end

        before do
          group.add_developer(user2)
        end

        it 'exports group members as group owner' do
          group.add_owner(user)

          expect(member_emails).to include('group@member.com')
        end

        context 'as admin' do
          let(:user) { create(:admin) }

          it 'exports group members as admin' do
            expect(member_emails).to include('group@member.com')
          end

          it 'exports group members' do
            member_types = saved_group_json['members'].map { |pm| pm['source_type'] }

            expect(member_types).to all(eq('Namespace'))
          end
        end
      end

      context 'group attributes' do
        shared_examples 'excluded attributes' do
          excluded_attributes = %w[
            id
            owner_id
            parent_id
            created_at
            updated_at
            runners_token
            runners_token_encrypted
            saml_discovery_token
          ]

          excluded_attributes.each do |excluded_attribute|
            it 'does not contain excluded attribute' do
              expect(saved_group_json).not_to include(excluded_attribute => group.public_send(excluded_attribute))
            end
          end
        end

        include_examples 'excluded attributes'
      end
    end
  end

  def setup_group
    group = create(:group, description: 'description')
    sub_group = create(:group, description: 'description', parent: group)
    create(:group, description: 'description', parent: sub_group)
    create(:milestone, group: group)
    create(:group_badge, group: group)
    group_label = create(:group_label, group: group)
    create(:label_priority, label: group_label, priority: 1)
    board = create(:board, group: group, milestone_id: Milestone::Upcoming.id)
    create(:list, board: board, label: group_label)
    create(:group_badge, group: group)

    group
  end

  def group_json(filename)
    ::JSON.parse(IO.read(filename))
  end
end

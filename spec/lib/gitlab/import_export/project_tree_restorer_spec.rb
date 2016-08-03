require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeRestorer, services: true do
  describe 'restore project tree' do

    let(:user) { create(:user) }
    let(:namespace) { create(:namespace, owner: user) }
    let(:shared) { Gitlab::ImportExport::Shared.new(relative_path: "", project_path: 'path') }
    let(:project) { create(:empty_project, name: 'project', path: 'project') }
    let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }
    let(:restored_project_json) { project_tree_restorer.restore }

    before do
      allow(shared).to receive(:export_path).and_return('spec/lib/gitlab/import_export/')
    end

    context 'JSON' do
      it 'restores models based on JSON' do
        expect(restored_project_json).to be true
      end

      it 'creates a valid pipeline note' do
        restored_project_json

        expect(Ci::Pipeline.first.notes).not_to be_empty
      end

      it 'restores the correct event with symbolised data' do
        restored_project_json

        expect(Event.where.not(data: nil).first.data[:ref]).not_to be_empty
      end

      it 'preserves updated_at on issues' do
        restored_project_json

        issue = Issue.where(description: 'Aliquam enim illo et possimus.').first

        expect(issue.reload.updated_at.to_s).to eq('2016-06-14 15:02:47 UTC')
      end

      context 'event at forth level of the tree' do
        let(:event) { Event.where(title: 'test levels').first }

        before do
          restored_project_json
        end

        it 'restores the event' do
          expect(event).not_to be_nil
        end

        it 'event belongs to note, belongs to merge request, belongs to a project' do
          expect(event.note.noteable.project).not_to be_nil
        end
      end

      it 'has the correct data for merge request st_diffs' do
        # makes sure we are renaming the custom method +utf8_st_diffs+ into +st_diffs+

        expect { restored_project_json }.to change(MergeRequestDiff.where.not(st_diffs: nil), :count).by(9)
      end

      it 'has labels associated to label links, associated to issues' do
        restored_project_json

        expect(Label.first.label_links.first.target).not_to be_nil
      end

      it 'has milestones associated to issues' do
        restored_project_json

        expect(Milestone.find_by_description('test milestone').issues).not_to be_empty
      end
    end
  end
end

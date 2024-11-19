# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::DesignManagementService, feature_category: :design_management do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }

  let(:instance) { described_class.new(noteable: instance_noteable, container: instance_project, author: instance_author) }

  describe '#design_version_added' do
    let(:instance_noteable) { version.issue }
    let(:instance_project) { version.issue.project }
    let(:instance_author) { version.author }

    subject { instance.design_version_added(version) }

    # default (valid) parameters:
    let(:n_designs) { 3 }
    let(:designs) { create_list(:design, n_designs, issue: issue) }
    let(:user) { build(:user) }
    let(:version) do
      create(:design_version, issue: issue, designs: designs)
    end

    before do
      # Avoid needing to call into gitaly
      allow(version).to receive(:author).and_return(user)
    end

    context 'with one kind of event' do
      before do
        DesignManagement::Action
          .where(design: designs).update_all(event: :modification)
      end

      it 'makes just one note' do
        expect(subject).to contain_exactly(Note)
      end

      it 'adds a new system note' do
        expect { subject }.to change { Note.system.count }.by(1)
      end
    end

    context 'with a mixture of events' do
      let(:n_designs) { DesignManagement::Action.events.size }

      before do
        designs.each_with_index do |design, i|
          design.actions.update_all(event: i)
        end
      end

      it 'makes one note for each kind of event' do
        expect(subject).to have_attributes(size: n_designs)
      end

      it 'adds a system note for each kind of event' do
        expect { subject }.to change { Note.system.count }.by(n_designs)
      end
    end

    describe 'icons' do
      where(:action) do
        [
          [:creation],
          [:modification],
          [:deletion]
        ]
      end

      with_them do
        before do
          version.actions.update_all(event: action)
        end

        subject(:metadata) do
          instance.design_version_added(version)
            .first.system_note_metadata
        end

        it 'has a valid action' do
          expect(::SystemNoteHelper::ICON_NAMES_BY_ACTION)
            .to include(metadata.action)
        end
      end
    end

    context 'it succeeds' do
      where(:action, :icon, :human_description) do
        [
          [:creation,     'designs_added',    'added'],
          [:modification, 'designs_modified', 'updated'],
          [:deletion,     'designs_removed',  'removed']
        ]
      end

      with_them do
        before do
          version.actions.update_all(event: action)
        end

        let(:anchor_tag) { %r{ <a[^>]*>#{link}</a>} }
        let(:href) { instance.send(:designs_path, { version: version.id }) }
        let(:link) { "#{n_designs} designs" }

        subject(:note) { instance.design_version_added(version).first }

        it 'has the correct data' do
          expect(note)
            .to be_system
            .and have_attributes(
              system_note_metadata: have_attributes(action: icon),
              note: include(human_description)
                      .and(include link)
                      .and(include href),
              note_html: a_string_matching(anchor_tag)
            )
        end
      end
    end
  end

  describe '#design_discussion_added' do
    let(:instance_noteable) { design.issue }
    let(:instance_project) { design.issue.project }
    let(:instance_author) { discussion_note.author }

    subject { instance.design_discussion_added(discussion_note) }

    let(:design) { create(:design, :with_file, issue: issue) }
    let(:author) { create(:user) }
    let(:discussion_note) do
      create(:diff_note_on_design, noteable: design, author: author)
    end

    let(:action) { 'designs_discussion_added' }

    it_behaves_like 'a system note' do
      let(:noteable) { discussion_note.noteable.issue }
    end

    it 'adds a new system note' do
      expect { subject }.to change { Note.system.count }.by(1)
    end

    it 'has the correct note text' do
      href = instance.send(:designs_path,
        { vueroute: design.filename, anchor: ActionView::RecordIdentifier.dom_id(discussion_note) }
      )

      expect(subject.note).to eq("started a discussion on [#{design.filename}](#{href})")
    end
  end
end

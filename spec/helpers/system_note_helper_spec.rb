# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNoteHelper, feature_category: :code_review_workflow do
  describe '.system_note_icon_name' do
    subject(:system_note_icon_name) { helper.system_note_icon_name(note) }

    context 'for an requested changes note' do
      let_it_be(:note) { build_stubbed(:note, :system) }
      let_it_be(:system_note_metadata) { build_stubbed(:system_note_metadata, note: note, action: :requested_changes) }

      it 'returns the iteration icon name' do
        expect(system_note_icon_name).to eq('error')
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Events::RenderService, feature_category: :user_profile do
  describe '#execute' do
    let!(:note) { build(:note) }
    let!(:event) { build(:event, target: note, project: note.project) }
    let!(:user) { build(:user) }

    context 'when the request format is atom' do
      it 'renders the note inside events' do
        expect(Banzai::ObjectRenderer).to receive(:new)
          .with(user: user, redaction_context: { only_path: false, xhtml: true })
          .and_call_original

        expect_any_instance_of(Banzai::ObjectRenderer)
          .to receive(:render).with([note], :note)

        described_class.new(user).execute([event], atom_request: true)
      end
    end

    context 'when the request format is not atom' do
      it 'renders the note inside events' do
        expect(Banzai::ObjectRenderer).to receive(:new)
          .with(user: user, redaction_context: {})
          .and_call_original

        expect_any_instance_of(Banzai::ObjectRenderer)
          .to receive(:render).with([note], :note)

        described_class.new(user).execute([event], atom_request: false)
      end
    end
  end
end

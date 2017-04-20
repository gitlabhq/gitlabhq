require 'spec_helper'

describe Banzai::ObjectRenderer do
  let(:project) { create(:empty_project) }
  let(:user) { project.owner }
  let(:renderer) { described_class.new(project, user, custom_value: 'value') }
  let(:object) { Note.new(note: 'hello', note_html: '<p>hello</p>') }

  describe '#render' do
    it 'renders and redacts an Array of objects' do
      renderer.render([object], :note)

      expect(object.redacted_note_html).to eq '<p>hello</p>'
      expect(object.user_visible_reference_count).to eq 0
    end

    it 'calls Banzai::Redactor to perform redaction' do
      expect_any_instance_of(Banzai::Redactor).to receive(:redact).and_call_original

      renderer.render([object], :note)
    end

    it 'retrieves field content using Banzai.render_field' do
      expect(Banzai).to receive(:render_field).with(object, :note).and_call_original

      renderer.render([object], :note)
    end

    it 'passes context to PostProcessPipeline' do
      another_user = create(:user)
      another_project = create(:empty_project)
      object = Note.new(
        note: 'hello',
        note_html: 'hello',
        author: another_user,
        project: another_project
      )

      expect(Banzai::Pipeline::PostProcessPipeline).to receive(:to_document).with(
        anything,
        hash_including(
          skip_redaction: true,
          current_user: user,
          project: another_project,
          author: another_user,
          custom_value: 'value'
        )
      ).and_call_original

      renderer.render([object], :note)
    end
  end
end

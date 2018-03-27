require 'spec_helper'

describe Banzai::ObjectRenderer do
  let(:project) { create(:project, :repository) }
  let(:user) { project.owner }
  let(:renderer) { described_class.new(project, user, custom_value: 'value') }
  let(:object) { Note.new(note: 'hello', note_html: '<p dir="auto">hello</p>', cached_markdown_version: CacheMarkdownField::CACHE_VERSION) }

  describe '#render' do
    context 'with cache' do
      it 'renders and redacts an Array of objects' do
        renderer.render([object], :note)

        expect(object.redacted_note_html).to eq '<p dir="auto">hello</p>'
        expect(object.user_visible_reference_count).to eq 0
      end

      it 'calls Banzai::Redactor to perform redaction' do
        expect_any_instance_of(Banzai::Redactor).to receive(:redact).and_call_original

        renderer.render([object], :note)
      end

      it 'retrieves field content using Banzai::Renderer.render_field' do
        expect(Banzai::Renderer).to receive(:render_field).with(object, :note, {}).and_call_original

        renderer.render([object], :note)
      end

      it 'passes context to PostProcessPipeline' do
        another_user = create(:user)
        another_project = create(:project)
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

    context 'without cache' do
      let(:commit) { project.commit }

      it 'renders and redacts an Array of objects' do
        renderer.render([commit], :title)

        expect(commit.redacted_title_html).to eq("Merge branch 'branch-merged' into 'master'")
      end

      it 'calls Banzai::Redactor to perform redaction' do
        expect_any_instance_of(Banzai::Redactor).to receive(:redact).and_call_original

        renderer.render([commit], :title)
      end

      it 'retrieves field content using Banzai::Renderer.cacheless_render_field' do
        expect(Banzai::Renderer).to receive(:cacheless_render_field).with(commit, :title, {}).and_call_original

        renderer.render([commit], :title)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ObjectRenderer, feature_category: :markdown do
  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }
  let(:renderer) do
    described_class.new(
      default_project: project,
      user: user,
      redaction_context: { custom_value: 'value' }
    )
  end

  let(:object) { Note.new(note: 'hello', note_html: '<p dir="auto">hello</p>', cached_markdown_version: Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION_SHIFTED) }

  describe '#render' do
    context 'with cache' do
      it 'renders and redacts an Array of objects' do
        renderer.render([object], :note)

        expect(object.redacted_note_html).to eq '<p dir="auto">hello</p>'
        expect(object.user_visible_reference_count).to eq 0
      end

      it 'calls Banzai::ReferenceRedactor to perform redaction' do
        expect_next_instance_of(Banzai::ReferenceRedactor) do |instance|
          expect(instance).to receive(:redact).and_call_original
        end

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
      let(:cacheless_class) do
        Class.new do
          attr_accessor :title, :redacted_title_html, :project

          def banzai_render_context(field)
            { project: project, pipeline: :single_line }
          end
        end
      end

      let(:cacheless_thing) do
        cacheless_class.new.tap do |thing|
          thing.title = "Merge branch 'branch-merged' into 'master'"
          thing.project = project
        end
      end

      it 'renders and redacts an Array of objects' do
        renderer.render([cacheless_thing], :title)

        expect(cacheless_thing.redacted_title_html).to eq("Merge branch 'branch-merged' into 'master'")
      end

      it 'calls Banzai::ReferenceRedactor to perform redaction' do
        expect_next_instance_of(Banzai::ReferenceRedactor) do |instance|
          expect(instance).to receive(:redact).and_call_original
        end

        renderer.render([cacheless_thing], :title)
      end

      it 'retrieves field content using Banzai::Renderer.cacheless_render_field' do
        expect(Banzai::Renderer).to receive(:cacheless_render_field).with(cacheless_thing, :title, {}).and_call_original

        renderer.render([cacheless_thing], :title)
      end
    end
  end
end

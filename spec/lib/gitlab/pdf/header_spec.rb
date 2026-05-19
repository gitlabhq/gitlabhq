# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Header, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }

  let(:page_number) { '12345' }
  let(:logo) { Rails.root.join('app/assets/images/gitlab_logo.png') }
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  describe '.render' do
    subject(:render) do
      described_class.render(pdf, project, page: page_number, height: 123)
    end

    let(:mock_instance) { instance_double(described_class) }

    before do
      allow(mock_instance).to receive(:render)
      allow(described_class).to receive(:new).and_return(mock_instance)
    end

    it 'creates a new instance and calls render on it' do
      render

      expect(described_class).to have_received(:new).with(pdf, page_number, 123, project).once
      expect(mock_instance).to have_received(:render).exactly(:once)
    end
  end

  describe '#render' do
    before do
      allow(pdf).to receive(:image).and_call_original
      allow(pdf).to receive(:formatted_text_box).and_call_original
      allow(pdf).to receive(:svg).and_call_original
    end

    shared_examples 'common header elements' do
      it 'includes the gitlab logo in the header' do
        render_header

        expect(pdf).to have_received(:image).with(logo, any_args).once
      end

      it 'includes the gitlab name in the header' do
        allow(pdf).to receive(:text_box).and_call_original

        render_header

        expect(pdf).to have_received(:text_box).with('GitLab', any_args).once
      end

      it 'includes the page number in the header' do
        render_header

        expect(pdf).to have_received(:formatted_text_box).with(
          array_including(hash_including(text: / \| .*#{page_number}/)),
          any_args
        )
      end

      it 'includes the svg divider in the header' do
        render_header

        gradient_svg = %r{<linearGradient}
        expect(pdf).to have_received(:svg).with(gradient_svg, any_args).once
      end
    end

    context 'with a project exportable' do
      subject(:render_header) { described_class.render(pdf, project, page: page_number, height: 123) }

      include_examples 'common header elements'

      it 'includes the "Project" label' do
        render_header

        expect(pdf).to have_received(:formatted_text_box).with(
          array_including(hash_including(text: 'Project: ')),
          any_args
        )
      end

      it 'renders the project name in bold' do
        render_header

        expect(pdf).to have_received(:formatted_text_box).with(
          array_including(hash_including(text: project.name, styles: [:bold])),
          any_args
        )
      end
    end

    context 'with a group exportable' do
      subject(:render_header) { described_class.render(pdf, group, page: page_number, height: 123) }

      include_examples 'common header elements'

      it 'includes the "Group" label' do
        render_header

        expect(pdf).to have_received(:formatted_text_box).with(
          array_including(hash_including(text: 'Group: ')),
          any_args
        )
      end

      it 'renders the group name in bold' do
        render_header

        expect(pdf).to have_received(:formatted_text_box).with(
          array_including(hash_including(text: group.name, styles: [:bold])),
          any_args
        )
      end
    end
  end
end

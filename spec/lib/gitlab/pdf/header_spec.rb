# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Header, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }

  let(:page_number) { '12345' }
  let(:logo) { Rails.root.join('app/assets/images/gitlab_logo.png') }

  describe '.render' do
    subject(:render) { described_class.render(pdf, page: page_number, height: 123) }

    let(:mock_instance) { instance_double(described_class) }

    before do
      allow(mock_instance).to receive(:render)
      allow(described_class).to receive(:new).and_return(mock_instance)
    end

    it 'creates a new instance and calls render on it' do
      render

      expect(described_class).to have_received(:new).with(pdf, page_number, 123).once
      expect(mock_instance).to have_received(:render).exactly(:once)
    end
  end

  describe '#render' do
    subject(:render_header) { described_class.render(pdf, page: page_number) }

    before do
      allow(pdf).to receive(:image).and_call_original
      allow(pdf).to receive(:text_box).and_call_original
      allow(pdf).to receive(:svg).and_call_original
    end

    it 'includes the gitlab logo in the header' do
      render_header

      expect(pdf).to have_received(:image).with(logo, any_args).once
    end

    it 'includes the gitlab name in the header' do
      render_header

      expect(pdf).to have_received(:text_box).with('GitLab', any_args).once
    end

    it 'includes the page number in the header' do
      render_header

      expect(pdf).to have_received(:text_box).with(/^.*#{page_number}/, any_args).once
    end

    it 'includes the svg divider in the header' do
      render_header

      expect(pdf).to have_received(:svg).with(%r{<svg.*</svg>}m, any_args).once
    end
  end
end

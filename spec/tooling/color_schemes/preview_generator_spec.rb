# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../tooling/lib/tooling/color_schemes/preview_generator'

RSpec.describe Tooling::ColorSchemes::PreviewGenerator, feature_category: :user_profile do
  let(:generator) { described_class.new(root: Rails.root.to_s) }

  def in_scheme_root(scss:, scheme: 'test')
    Dir.mktmpdir do |root|
      themes_dir = File.join(root, 'app/assets/stylesheets/highlight/themes')
      FileUtils.mkdir_p(themes_dir)
      File.write(File.join(themes_dir, "#{scheme}.scss"), scss)

      yield root
    end
  end

  describe '#schemes' do
    it 'covers every selectable color scheme' do
      expect(generator.schemes).to match_array(Gitlab::ColorSchemes.available_schemes.map(&:css_class))
    end
  end

  describe '#color_map' do
    it 'parses token colors from the scheme stylesheet' do
      expect(generator.color_map('dracula')).to include(
        'k' => '#ff79c6',  # keyword
        'nc' => '#50fa7b', # class name
        'vi' => '#8be9fd', # instance variable
        'no' => '#f8f8f2'  # constant
      )
    end

    it 'merges token colors from the shared light base file' do
      # white defines its tokens in _white_base.scss, not in white.scss.
      expect(generator.color_map('white')).to include('n' => '#333')
    end

    it 'captures hyphenated token names' do
      expect(generator.color_map('dracula')).to include('text-color' => '#f8f8f2')
    end

    it 'captures 8-digit hex values with an alpha channel' do
      in_scheme_root(scss: "$test-new-idiff: #50fa7b26;\n") do |root|
        expect(described_class.new(root: root).color_map('test')).to eq('new-idiff' => '#50fa7b26')
      end
    end
  end

  describe '#html_for' do
    it 'is idempotent: repeated calls render identical HTML for every scheme' do
      generator.schemes.each do |scheme|
        first = generator.html_for(scheme)
        second = generator.html_for(scheme)

        expect(first).to eq(second)
      end
    end

    it 'colors each token with its class color from the stylesheet', :aggregate_failures do
      html = generator.html_for('dracula')

      expect(html).to include('<span style="color:#ff79c6">class</span>')               # keyword
      expect(html).to include('<span style="color:#50fa7b">DoctypesController</span>')  # class name
      expect(html).to include('<span style="color:#8be9fd">@doctypes</span>')           # instance variable
      expect(html).to include('<span style="color:#f8f8f2">Doctype</span>')             # constant
    end

    it 'falls back to the structural fg for a theme with no token colors in scss', :aggregate_failures do
      # "none" defines structural variables (`code-mark`) but no Rouge token
      # colors like `n`, so every token uses meta[:fg].
      html = generator.html_for('none')

      expect(generator.color_map('none')).not_to include('n')
      expect(html).to include('<span style="color:#737278">class</span>')
    end

    it 'falls back to the text-color token for a scheme without an `n` color' do
      in_scheme_root(scheme: 'white', scss: "$white-text-color: #123456;\n") do |root|
        html = described_class.new(root: root).html_for('white')

        expect(html).to include('<span style="color:#123456">class</span>')
      end
    end

    it 'renders a thumbnail body for every scheme', :aggregate_failures do
      generator.schemes.each do |scheme|
        html = generator.html_for(scheme)

        expect(html).to include('class="code"')
        expect(html).to include(described_class::STRUCTURAL.fetch(scheme)[:bg])
      end
    end
  end

  describe '#downscale_html' do
    it 'embeds the image at the final thumbnail size', :aggregate_failures do
      html = generator.downscale_html('file:///tmp/example@2x.png')

      expect(html).to include('<img src="file:///tmp/example@2x.png">')
      expect(html).to include("width:#{described_class::WIDTH}px")
      expect(html).to include("height:#{described_class::HEIGHT}px")
    end

    it 'is idempotent for the same image' do
      first = generator.downscale_html('a.png')
      second = generator.downscale_html('a.png')

      expect(first).to eq(second)
    end
  end
end

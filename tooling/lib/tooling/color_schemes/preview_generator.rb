# frozen_string_literal: true

require 'rouge'
require 'erb'

module Tooling
  module ColorSchemes
    # Renders the syntax-highlighting scheme preview thumbnails shown in user
    # preferences. #html_for is pure and deterministic (the part specs cover); the
    # rake task feeds its output through headless Chrome and pngquant.
    class PreviewGenerator
      # Each line is self-contained, so the per-line lexing in #html_for is accurate.
      SNIPPET = <<~RUBY
        class DoctypesController
          def index
            @doctypes = Doctype.all
          end

          def show
      RUBY

      # bg/border aren't read from #color_map because light themes express them as
      # design-system tokens (not plain hex), so they can't be derived uniformly.
      # `light` picks the line-number color; `fg` overrides the token color for
      # themes whose text comes from a design-system token rather than `$<scheme>-n`.
      STRUCTURAL = {
        'white' => { light: true, bg: '#ffffff', border: '#dcdcde' },
        'dark' => { light: false, bg: '#1d1f21', border: '#808080' },
        'solarized-light' => { light: true, bg: '#fdf6e3', border: '#c5d0d4' },
        'solarized-dark' => { light: false, bg: '#002b36', border: '#113b46' },
        'monokai' => { light: false, bg: '#272822', border: '#555555' },
        'dracula' => { light: false, bg: '#282a36', border: '#44475a' },
        'none' => { light: true, bg: '#fbfafd', border: '#dcdcde', fg: '#737278' }
      }.freeze

      DARK_LINE_NUMBER = 'rgba(255,255,255,0.3)'
      LIGHT_LINE_NUMBER = 'rgba(5,5,6,0.24)'

      # Render at this scale and downscale, so the 12px text edges come out smooth.
      SUPERSAMPLE = 2
      WIDTH = 160
      HEIGHT = 100

      TEMPLATE = <<~HTML
        <!doctype html><html><head><meta charset="utf-8"><style>
        @font-face{font-family:'GitLab Mono';src:url('<%= font_uri %>') format('woff2');}
        html,body{margin:0;padding:0}
        body{width:<%= WIDTH %>px;height:<%= HEIGHT %>px;background:<%= bg %>;overflow:hidden}
        .code{font-family:'GitLab Mono',monospace;font-size:12px;line-height:16px;padding-top:4px;-webkit-font-smoothing:antialiased}
        .row{display:grid;grid-template-columns:26px 1fr;height:16px}
        .ln{padding-left:8px;box-sizing:border-box;text-align:left;color:<%= linenum %>;border-right:1px solid <%= border %>}
        .src{padding-left:10px;box-sizing:border-box;white-space:pre;overflow:hidden;min-width:0}
        </style></head><body><div class="code"><%= rows %></div></body></html>
      HTML

      def initialize(root:)
        @root = root
      end

      def schemes
        STRUCTURAL.keys
      end

      def font_path
        File.join(@root, 'node_modules/@gitlab/fonts/gitlab-mono/GitLabMono.woff2')
      end

      def output_path(scheme)
        File.join(@root, 'app/assets/images', "#{scheme}-scheme-preview.png")
      end

      # Light themes keep some token colors in the shared base file, so read both.
      def color_map(scheme)
        files = [
          File.join(@root, 'app/assets/stylesheets/highlight/themes', "#{scheme}.scss"),
          File.join(@root, 'app/assets/stylesheets/highlight/_white_base.scss')
        ]

        pattern = /\$#{Regexp.escape(scheme)}-([\w-]+):\s*(#[0-9a-fA-F]{3,8}|rgba?\([^)]*\))/

        files.each_with_object({}) do |path, colors|
          next unless File.exist?(path)

          File.read(path).scan(pattern) do |token, color|
            colors[token] ||= color
          end
        end
      end

      def html_for(scheme)
        meta = STRUCTURAL.fetch(scheme)
        colors = color_map(scheme)
        render(meta, code_rows(colors, foreground(colors, meta)))
      end

      # Downscaling here (instead of screenshotting at 1x) lets Chrome resample the
      # 2x render, which is what smooths the glyph edges.
      def downscale_html(image_uri)
        <<~HTML
          <!doctype html><html><head><style>
          html,body{margin:0;padding:0}
          img{width:#{WIDTH}px;height:#{HEIGHT}px;display:block}
          </style></head><body><img src="#{image_uri}"></body></html>
        HTML
      end

      private

      # `none` defines no token colors, so it relies entirely on meta[:fg].
      def foreground(colors, meta)
        colors['n'] || meta[:fg] || colors['text-color'] || '#000000'
      end

      def code_rows(colors, fg)
        SNIPPET.each_line.with_index(1).map do |text, idx|
          spans = Rouge::Lexers::Ruby.lex(text.chomp).map do |token, value|
            %(<span style="color:#{colors[token.shortname.to_s] || fg}">#{ERB::Util.html_escape(value)}</span>)
          end.join
          %(<div class="row"><span class="ln">#{idx}</span><span class="src">#{spans}</span></div>)
        end.join
      end

      def render(meta, rows)
        bg = meta[:bg]
        border = meta[:border]
        linenum = meta[:light] ? LIGHT_LINE_NUMBER : DARK_LINE_NUMBER
        font_uri = "file://#{font_path}"
        ERB.new(TEMPLATE).result(binding)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rouge::Formatters::HTMLGitlab do
  describe '#format' do
    subject { described_class.format(tokens, **options) }

    let(:lang) { 'ruby' }
    let(:lexer) { Rouge::Lexer.find_fancy(lang) }
    let(:tokens) { lexer.lex("def hello", continue: false) }
    let(:options) { { tag: lang } }

    context 'when svg and indexes are present to trim' do
      let(:options) { { tag: lang, ellipsis_indexes: [0], ellipsis_svg: "svg_icon" } }

      it 'returns highlighted ruby code with svg' do
        code = %q{<span id="LC1" class="line" lang="ruby"><span class="k">def</span> <span class="nf">hello</span><span class="gl-px-2 gl-rounded-base gl-mx-2 gl-bg-gray-100 gl-cursor-help has-tooltip" title="Content has been trimmed">svg_icon</span></span>}

        is_expected.to eq(code)
      end
    end

    it 'returns highlighted ruby code' do
      code = %q{<span id="LC1" class="line" lang="ruby"><span class="k">def</span> <span class="nf">hello</span></span>}

      is_expected.to eq(code)
    end

    context 'when options are empty' do
      let(:options) { {} }

      it 'returns highlighted code without language' do
        code = %q{<span id="LC1" class="line" lang=""><span class="k">def</span> <span class="nf">hello</span></span>}

        is_expected.to eq(code)
      end
    end

    context 'when line number is provided' do
      let(:options) { { tag: lang, line_number: 10 } }

      it 'returns highlighted ruby code with correct line number' do
        code = %q{<span id="LC10" class="line" lang="ruby"><span class="k">def</span> <span class="nf">hello</span></span>}

        is_expected.to eq(code)
      end
    end

    context 'when unicode control characters are used' do
      let(:lang) { 'javascript' }
      let(:tokens) { lexer.lex(code, continue: false) }
      let(:code) do
        <<~JS
          #!/usr/bin/env node

          var accessLevel = "user";
          if (accessLevel != "user‮ ⁦// Check if admin⁩ ⁦") {
              console.log("You are an admin.");
          }
        JS
      end

      it 'highlights the control characters' do
        message = "Potentially unwanted character detected: Unicode BiDi Control"

        is_expected.to include(%{<span class="unicode-bidi has-tooltip" data-toggle="tooltip" title="#{message}">}).exactly(4).times
      end
    end
  end
end

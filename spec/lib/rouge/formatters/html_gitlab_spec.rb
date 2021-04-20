# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rouge::Formatters::HTMLGitlab do
  describe '#format' do
    subject { described_class.format(tokens, options) }

    let(:lang) { 'ruby' }
    let(:lexer) { Rouge::Lexer.find_fancy(lang) }
    let(:tokens) { lexer.lex("def hello", continue: false) }
    let(:options) { { tag: lang } }

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
  end
end

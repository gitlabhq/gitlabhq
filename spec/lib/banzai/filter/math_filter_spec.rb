# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MathFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'add js-render to all math' do
    markdown = <<~MARKDOWN
    $`2+2`$ + $3+3$ + $$4+4$$

    $$
    5+5
    $$

    ```math
    6+6
    ```
    MARKDOWN

    doc = pipeline_filter(markdown)

    expect(doc.search('.js-render-math').count).to eq(5)
  end

  context 'when limiting how many elements can be marked as math' do
    let_it_be(:context) { {} }

    subject { pipeline_filter('$`2+2`$ + $3+3$ + $$4+4$$', context) }

    before do
      stub_const('Banzai::Filter::MathFilter::RENDER_NODES_LIMIT', 2)
    end

    it 'enforces limits by default' do
      expect(subject.search('.js-render-math').count).to eq(2)
    end

    context 'when project with user namespace (no group)' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:context) { { project: project } }

      it 'limits' do
        expect(subject.search('.js-render-math').count).to eq(2)
      end
    end

    context 'when project with group, no namespace settings' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :public, group: group) }
      let_it_be(:context) { { project: project } }

      it 'limits' do
        expect(subject.search('.js-render-math').count).to eq(2)
      end
    end

    context 'when project with group, default namespace settings' do
      let_it_be(:namespace_settings) { create(:namespace_settings) }
      let_it_be(:group) { create(:group, namespace_settings: namespace_settings) }
      let_it_be(:project) { create(:project, :public, group: group) }
      let_it_be(:context) { { project: project } }

      it 'limits' do
        expect(subject.search('.js-render-math').count).to eq(2)
      end
    end

    context 'when limits math_rendering_limits_enabled is false' do
      let_it_be(:namespace_settings) { create(:namespace_settings, math_rendering_limits_enabled: false) }
      let_it_be(:group) { create(:group, namespace_settings: namespace_settings) }
      let_it_be(:project) { create(:project, :public, group: group) }
      let_it_be(:context) { { project: project } }

      it 'does not limit' do
        expect(subject.search('.js-render-math').count).to eq(3)
      end
    end

    context 'when for wikis' do
      let_it_be(:context) { { wiki: true } }

      it 'does limit' do
        expect(subject.search('.js-render-math').count).to eq(2)
      end
    end

    context 'when for blobs' do
      let_it_be(:context) { { text_source: :blob } }

      it 'does limit for blobs' do
        expect(subject.search('.js-render-math').count).to eq(2)
      end
    end
  end

  # TODO: This portion is legacy code, and is only used with the Ruby parser.
  # The current markdown parser now properly handles math.
  # The Ruby parser is now only for benchmarking purposes.
  # issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601
  #
  # Note that the "extensive" syntax testing for the new math filter
  # is now handled in https://gitlab.com/gitlab-org/ruby/gems/gitlab-glfm-markdown/-/blob/main/spec/math_spec.rb
  describe 'legacy math filter' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:context) { { markdown_engine: Banzai::Filter::MarkdownFilter::CMARK_ENGINE } }

    shared_examples 'inline math' do
      it 'removes surrounding dollar signs and adds class code, math and js-render-math' do
        doc = legacy_pipeline_filter(text, context)

        expected = result_template.gsub('<math>', '<code data-math-style="inline" class="code math js-render-math">')
        expected.gsub!('</math>', '</code>')

        expect(doc.to_s).to eq expected
      end
    end

    shared_examples 'display math' do
      let_it_be(:template_prefix_with_pre) { '<pre data-canonical-lang="math" data-math-style="display" class="js-render-math"><code>' }
      let_it_be(:template_prefix_with_code) { '<code data-math-style="display" class="code math js-render-math">' }
      let(:use_pre_tags) { false }

      it 'removes surrounding dollar signs and adds class code, math and js-render-math' do
        doc = legacy_pipeline_filter(text, context)

        template_prefix = use_pre_tags ? template_prefix_with_pre : template_prefix_with_code
        template_suffix = "</code>#{'</pre>' if use_pre_tags}"
        expected = result_template.gsub('<math>', template_prefix)
        expected.gsub!('</math>', template_suffix)

        expect(doc.to_s).to eq expected
      end
    end

    describe 'inline math using $...$ syntax' do
      context 'with valid syntax' do
        where(:text, :result_template) do
          '$2+2$'                                  | '<p><math>2+2</math></p>'
          '$22+1$ and $22 + a^2$'                  | '<p><math>22+1</math> and <math>22 + a^2</math></p>'
          '$22 and $2+2$'                          | '<p>$22 and <math>2+2</math></p>'
          '$2+2$ $22 and flightjs/Flight$22 $2+2$' | '<p><math>2+2</math> $22 and flightjs/Flight$22 <math>2+2</math></p>'
          '$1/2$ &lt;b&gt;test&lt;/b&gt;'          | '<p><math>1/2</math> &lt;b&gt;test&lt;/b&gt;</p>'
          '$a!$'                                   | '<p><math>a!</math></p>'
          '$x$'                                    | '<p><math>x</math></p>'
          '$1+2\$$'                                | '<p><math>1+2\$</math></p>'
          '$1+\$2$'                                | '<p><math>1+\$2</math></p>'
          '$1+\%2$'                                | '<p><math>1+\%2</math></p>'
          '$1+\#2$'                                | '<p><math>1+\#2</math></p>'
          '$1+\&2$'                                | '<p><math>1+\&amp;2</math></p>'
          '$1+\{2$'                                | '<p><math>1+\{2</math></p>'
          '$1+\}2$'                                | '<p><math>1+\}2</math></p>'
          '$1+\_2$'                                | '<p><math>1+\_2</math></p>'
        end

        with_them do
          it_behaves_like 'inline math'
        end
      end
    end

    describe 'inline math using $`...`$ syntax' do
      context 'with valid syntax' do
        where(:text, :result_template) do
          '$`2+2`$'                                    | '<p><math>2+2</math></p>'
          '$`22+1`$ and $`22 + a^2`$'                  | '<p><math>22+1</math> and <math>22 + a^2</math></p>'
          '$22 and $`2+2`$'                            | '<p>$22 and <math>2+2</math></p>'
          '$`2+2`$ $22 and flightjs/Flight$22 $`2+2`$' | '<p><math>2+2</math> $22 and flightjs/Flight$22 <math>2+2</math></p>'
          'test $$`2+2`$$ test'                        | '<p>test $<math>2+2</math>$ test</p>'
          '$`1+\$2`$'                                  | '<p><math>1+\$2</math></p>'
        end

        with_them do
          it_behaves_like 'inline math'
        end
      end
    end

    describe 'inline display math using $$...$$ syntax' do
      context 'with valid syntax' do
        where(:text, :result_template) do
          '$$2+2$$'                                    | '<p><math>2+2</math></p>'
          '$$   2+2  $$'                               | '<p><math>2+2</math></p>'
          '$$22+1$$ and $$22 + a^2$$'                  | '<p><math>22+1</math> and <math>22 + a^2</math></p>'
          '$22 and $$2+2$$'                            | '<p>$22 and <math>2+2</math></p>'
          '$$2+2$$ $22 and flightjs/Flight$22 $$2+2$$' | '<p><math>2+2</math> $22 and flightjs/Flight$22 <math>2+2</math></p>'
          'flightjs/Flight$22 and $$a^2 + b^2 = c^2$$' | '<p>flightjs/Flight$22 and <math>a^2 + b^2 = c^2</math></p>'
          '$$a!$$'                                     | '<p><math>a!</math></p>'
          '$$x$$'                                      | '<p><math>x</math></p>'
          '$$20,000 and $$30,000'                      | '<p><math>20,000 and</math>30,000</p>'
        end

        with_them do
          it_behaves_like 'display math'
        end
      end
    end

    describe 'block display math using $$\n...\n$$ syntax' do
      context 'with valid syntax' do
        where(:text, :result_template) do
          "$$\n2+2\n$$"      | "<math>2+2\n</math>"
          "$$  \n2+2\n$$"    | "<math>2+2\n</math>"
          "$$\n2+2\n3+4\n$$" | "<math>2+2\n3+4\n</math>"
        end

        with_them do
          it_behaves_like 'display math' do
            let(:use_pre_tags) { true }
          end
        end
      end

      context 'when it spans multiple lines' do
        let(:math) do
          <<~MATH
           \\begin{align*}
           \\Delta t   \\frac{d(b_i, a_i)}{c} + \\Delta t_{b_i}
           \\end{align*}
          MATH
        end

        let(:text) { "$$\n#{math}$$" }
        let(:result_template) { "<math>#{math}</math>" }

        it_behaves_like 'display math' do
          let(:use_pre_tags) { true }
        end
      end

      context 'when it contains \\' do
        let(:math) do
          <<~MATH
            E = mc^2 \\\\
            E = \\$mc^2
          MATH
        end

        let(:text) { "$$\n#{math}$$" }
        let(:result_template) { "<math>#{math}</math>" }

        it_behaves_like 'display math' do
          let(:use_pre_tags) { true }
        end
      end
    end

    describe 'display math using ```math...``` syntax' do
      it 'adds data-math-style display attribute to display math' do
        doc = legacy_pipeline_filter("```math\n2+2\n```", context)
        pre = doc.xpath('descendant-or-self::pre').first

        expect(pre['data-math-style']).to eq 'display'
      end

      it 'adds js-render-math class to display math' do
        doc = legacy_pipeline_filter("```math\n2+2\n```", context)
        pre = doc.xpath('descendant-or-self::pre').first

        expect(pre[:class]).to include("js-render-math")
      end

      it 'ignores code blocks that are not math' do
        input = "```plaintext\n2+2\n```"
        doc = legacy_pipeline_filter(input, context)

        expect(doc.to_s).to eq "<pre data-canonical-lang=\"plaintext\"><code>2+2\n</code></pre>"
      end

      it 'requires the pre to contain both code and math' do
        input = '<pre data-canonical-lang="math">something</pre>'
        doc = legacy_pipeline_filter(input, context)

        expect(doc.to_s).to eq input
      end
    end

    describe 'unrecognized syntax' do
      where(:text, :result) do
        '`2+2`'               | '<p><code>2+2</code></p>'
        'test $`2+2` test'    | '<p>test $<code>2+2</code> test</p>'
        'test `2+2`$ test'    | '<p>test <code>2+2</code>$ test</p>'
        '$20,000 and $30,000' | '<p>$20,000 and $30,000</p>'
        '$20,000 in $USD'     | '<p>$20,000 in $USD</p>'
        '$ a^2 $'             | '<p>$ a^2 $</p>'
        "test $$\n2+2\n$$"    | "<p>test $$\n2+2\n$$</p>"
        "$\n$"                | "<p>$\n$</p>"
        '$$$'                 | '<p>$$$</p>'
        '`$1+2$`'             | '<p><code>$1+2$</code></p>'
        '`$$1+2$$`'           | '<p><code>$$1+2$$</code></p>'
        '`$\$1+2$$`'          | '<p><code>$\$1+2$$</code></p>'
      end

      with_them do
        it 'is ignored' do
          expect(legacy_pipeline_filter(text, context).to_s).to eq result
        end
      end
    end

    it 'handles multiple styles in one text block' do
      doc = legacy_pipeline_filter('$`2+2`$ + $3+3$ + $$4+4$$', context)

      expect(doc.search('.js-render-math').count).to eq(3)
      expect(doc.search('[data-math-style="inline"]').count).to eq(2)
      expect(doc.search('[data-math-style="display"]').count).to eq(1)
    end

    def legacy_pipeline_filter(text, context = {})
      context = { project: nil, no_sourcepos: true }.merge(context)

      doc = Banzai::Pipeline::PreProcessPipeline.call(text, {})
      doc = Banzai::Pipeline::PlainMarkdownPipeline.call(doc[:output], context)
      doc = Banzai::Filter::CodeLanguageFilter.call(doc[:output], context, nil)
      doc = Banzai::Filter::SanitizationFilter.call(doc, context, nil)
      doc = Banzai::Filter::SanitizeLinkFilter.call(doc, context, nil)

      filter(doc, context)
    end
  end

  it_behaves_like 'pipeline timing check'

  def pipeline_filter(text, context = {})
    context = { project: nil, no_sourcepos: true }.merge(context)

    doc = Banzai::Pipeline::PreProcessPipeline.call(text, {})
    doc = Banzai::Pipeline::FullPipeline.call(doc[:output], context)

    doc[:output]
  end
end

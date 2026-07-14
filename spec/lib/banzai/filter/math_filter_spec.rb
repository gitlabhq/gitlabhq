# frozen_string_literal: true

require 'spec_helper'

# note that extensive syntax test are performed in the parser,
# https://gitlab.com/gitlab-org/ruby/gems/gitlab-glfm-markdown/blob/main/spec/math_spec.rb
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

    expect(doc.search('.js-render-math').count).to eq(6)
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
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be(:project) { create(:project, :public, group: group) }
      let_it_be(:context) { { project: project } }

      it 'limits' do
        expect(subject.search('.js-render-math').count).to eq(2)
      end
    end

    context 'when project with group, default namespace settings' do
      let_it_be_with_reload(:namespace_settings) { create(:namespace_settings) }
      let_it_be_with_reload(:group) { create(:group, namespace_settings: namespace_settings) }
      let_it_be(:project) { create(:project, :public, group: group) }
      let_it_be(:context) { { project: project } }

      it 'limits' do
        expect(subject.search('.js-render-math').count).to eq(2)
      end
    end

    context 'when limits math_rendering_limits_enabled is false' do
      let_it_be_with_reload(:namespace_settings) do
        create(:namespace_settings, math_rendering_limits_enabled: false)
      end

      let_it_be_with_reload(:group) { create(:group, namespace_settings: namespace_settings) }
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

  context 'on pre elements with data-math-style' do
    let(:doc) { filter(html, {}) }
    let(:pre) { doc.at_css('pre') }

    context 'when a <pre data-canonical-lang="math"> has no data-math-style' do
      let(:html) { '<pre data-canonical-lang="math"><code>\sqrt{2}</code></pre>' }

      it 'sets the math style attribute' do
        expect(pre['data-math-style']).to eq('display')
        expect(pre[:class]).to eq('js-render-math')
      end
    end

    context 'when a <pre data-canonical-lang="math"> already has data-math-style' do
      let(:html) { '<pre data-canonical-lang="math" data-math-style="inline"><code>\sqrt{2}</code></pre>' }

      it 'preserves the math style attribute' do
        expect(pre['data-math-style']).to eq('inline')
        expect(pre[:class]).to eq('js-render-math')
      end
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

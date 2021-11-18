# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::PlantumlFilter do
  include FilterSpecHelper

  shared_examples_for 'renders correct markdown' do
    it 'replaces plantuml pre tag with img tag' do
      stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")

      input = if Feature.enabled?(:use_cmark_renderer)
                '<pre lang="plantuml"><code>Bob -> Sara : Hello</code></pre>'
              else
                '<pre><code lang="plantuml">Bob -> Sara : Hello</code></pre>'
              end

      output = '<div class="imageblock"><div class="content"><img class="plantuml" src="http://localhost:8080/png/U9npoazIqBLJ24uiIbImKl18pSd91m0rkGMq"></div></div>'
      doc = filter(input)

      expect(doc.to_s).to eq output
    end

    it 'does not replace plantuml pre tag with img tag if disabled' do
      stub_application_setting(plantuml_enabled: false)

      if Feature.enabled?(:use_cmark_renderer)
        input = '<pre lang="plantuml"><code>Bob -> Sara : Hello</code></pre>'
        output = '<pre lang="plantuml"><code>Bob -&gt; Sara : Hello</code></pre>'
      else
        input = '<pre><code lang="plantuml">Bob -> Sara : Hello</code></pre>'
        output = '<pre><code lang="plantuml">Bob -&gt; Sara : Hello</code></pre>'
      end

      doc = filter(input)

      expect(doc.to_s).to eq output
    end

    it 'does not replace plantuml pre tag with img tag if url is invalid' do
      stub_application_setting(plantuml_enabled: true, plantuml_url: "invalid")

      input = if Feature.enabled?(:use_cmark_renderer)
                '<pre lang="plantuml"><code>Bob -> Sara : Hello</code></pre>'
              else
                '<pre><code lang="plantuml">Bob -> Sara : Hello</code></pre>'
              end

      output = '<div class="listingblock"><div class="content"><pre class="plantuml plantuml-error"> Error: cannot connect to PlantUML server at "invalid"</pre></div></div>'
      doc = filter(input)

      expect(doc.to_s).to eq output
    end
  end

  context 'using ruby-based HTML renderer' do
    before do
      stub_feature_flags(use_cmark_renderer: false)
    end

    it_behaves_like 'renders correct markdown'
  end

  context 'using c-based HTML renderer' do
    before do
      stub_feature_flags(use_cmark_renderer: true)
    end

    it_behaves_like 'renders correct markdown'
  end
end

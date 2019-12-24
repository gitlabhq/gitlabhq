# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::PlantumlFilter do
  include FilterSpecHelper

  it 'replaces plantuml pre tag with img tag' do
    stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")
    input = '<pre><code lang="plantuml">Bob -> Sara : Hello</code></pre>'
    output = '<div class="imageblock"><div class="content"><img class="plantuml" src="http://localhost:8080/png/U9npoazIqBLJ24uiIbImKl18pSd91m0rkGMq"></div></div>'
    doc = filter(input)

    expect(doc.to_s).to eq output
  end

  it 'does not replace plantuml pre tag with img tag if disabled' do
    stub_application_setting(plantuml_enabled: false)
    input = '<pre><code lang="plantuml">Bob -> Sara : Hello</code></pre>'
    output = '<pre><code lang="plantuml">Bob -&gt; Sara : Hello</code></pre>'
    doc = filter(input)

    expect(doc.to_s).to eq output
  end

  it 'does not replace plantuml pre tag with img tag if url is invalid' do
    stub_application_setting(plantuml_enabled: true, plantuml_url: "invalid")
    input = '<pre><code lang="plantuml">Bob -> Sara : Hello</code></pre>'
    output = '<div class="listingblock"><div class="content"><pre class="plantuml plantuml-error"> Error: cannot connect to PlantUML server at "invalid"</pre></div></div>'
    doc = filter(input)

    expect(doc.to_s).to eq output
  end
end

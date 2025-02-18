# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::PlantumlFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'replaces plantuml pre tag with img tag' do
    stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")

    # Input rendered from the following Markdown:
    #
    # ```plantuml
    # Bob -> Sara : Hello
    # ```
    input = %(<pre data-canonical-lang="plantuml"><code>Bob -&gt; Sara : Hello\n</code></pre>)
    output = '<img class="plantuml" src="http://localhost:8080/png/U9npoazIqBLJ24uiIbImKl18pSd91m0rkGMq" data-diagram="plantuml" data-diagram-src="data:text/plain;base64,Qm9iIC0+IFNhcmEgOiBIZWxsbw==">'
    doc = filter(input)

    expect(doc.to_s).to eq output
  end

  it 'allows the lang attribute on the code tag to support RST files processed by gitlab-markup gem' do
    stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")

    # Input rendered from the following Markdown:
    #
    # ```plantuml
    # Bob -> Sara : Hello
    # ```
    input = %(<pre><code data-canonical-lang="plantuml">Bob -&gt; Sara : Hello\n</code></pre>)
    output = '<img class="plantuml" src="http://localhost:8080/png/U9npoazIqBLJ24uiIbImKl18pSd91m0rkGMq" data-diagram="plantuml" data-diagram-src="data:text/plain;base64,Qm9iIC0+IFNhcmEgOiBIZWxsbw==">'
    doc = filter(input)

    expect(doc.to_s).to eq output
  end

  it 'does not replace plantuml pre tag with img tag if disabled' do
    stub_application_setting(plantuml_enabled: false)

    # Input rendered from the following Markdown:
    #
    # ```plantuml
    # Bob -> Sara : Hello
    # ```
    input = %(<pre data-canonical-lang="plantuml"><code>Bob -&gt; Sara : Hello\n</code></pre>)
    doc = filter(input)

    expect(doc.to_s).to eq input
  end

  it 'does not replace plantuml pre tag with img tag if url is invalid' do
    stub_application_setting(plantuml_enabled: true, plantuml_url: "invalid")

    # Input rendered from the following Markdown:
    #
    # ```plantuml
    # Bob -> Sara : Hello
    # ```
    input = %(<pre data-canonical-lang="plantuml"><code>Bob -&gt; Sara : Hello\n</code></pre>)
    doc = filter(input)

    expect(doc.to_s).to eq input
  end

  it "strips at most one trailing newline from the diagram's source" do
    stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")

    # Input rendered from the following Markdown:
    #
    # ```plantuml
    # Bob -> Sara : Hello
    # ' Next line left intentionally blank.
    #
    # ```
    input = %(<pre data-canonical-lang="plantuml"><code>Bob -&gt; Sara : Hello\n' Next line left intentionally blank.\n\n</code></pre>)
    output = '<img class="plantuml" src="http://localhost:8080/png/U9npoazIqBLJ24uiIbImKl18pSd9vr9Ny4kjA578oSnBLSX9JIjHoCmhISqhoSpFIyp9gLH8oadCozRZ0W0Q7XD1" data-diagram="plantuml" data-diagram-src="data:text/plain;base64,Qm9iIC0+IFNhcmEgOiBIZWxsbwonIE5leHQgbGluZSBsZWZ0IGludGVudGlvbmFsbHkgYmxhbmsuCg==">'
    doc = filter(input)

    expect(doc.to_s).to eq output
  end

  it_behaves_like 'pipeline timing check'
end

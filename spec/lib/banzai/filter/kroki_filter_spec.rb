# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::KrokiFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'replaces nomnoml pre tag with img tag if kroki is enabled' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")

    # Input rendered from the following Markdown:
    #
    # ```nomnoml
    # [Pirate|eyeCount: Int|raid();pillage()|
    #   [beard]--[parrot]
    #   [beard]-:>[foul mouth]
    # ]
    # ```
    input = <<~INPUT.strip
      <pre data-canonical-lang="nomnoml"><code>[Pirate|eyeCount: Int|raid();pillage()|
        [beard]--[parrot]
        [beard]-:&gt;[foul mouth]
      ]
      </code></pre>
    INPUT
    doc = filter(input)

    expect(doc.to_s).to eq '<img src="http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KzhUlCITkpNLEqJ1dWNLkgsKsoviUUSs7KLTssvzVHIzS8tyYjligUAMhEd0g==" class="js-render-kroki" data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,W1BpcmF0ZXxleWVDb3VudDogSW50fHJhaWQoKTtwaWxsYWdlKCl8CiAgW2JlYXJkXS0tW3BhcnJvdF0KICBbYmVhcmRdLTo+W2ZvdWwgbW91dGhdCl0=">'
  end

  it 'replaces nomnoml pre tag with img tag if both kroki and plantuml are enabled' do
    stub_application_setting(
      kroki_enabled: true,
      kroki_url: "http://localhost:8000",
      plantuml_enabled: true,
      plantuml_url: "http://localhost:8080"
    )

    # Input rendered from the following Markdown:
    #
    # ```nomnoml
    # [Pirate|eyeCount: Int|raid();pillage()|
    #   [beard]--[parrot]
    #   [beard]-:>[foul mouth]
    # ]
    # ```
    input = <<~INPUT.strip
      <pre data-canonical-lang="nomnoml"><code>[Pirate|eyeCount: Int|raid();pillage()|
        [beard]--[parrot]
        [beard]-:&gt;[foul mouth]
      ]
      </code></pre>
    INPUT
    doc = filter(input)

    expect(doc.to_s).to eq '<img src="http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KzhUlCITkpNLEqJ1dWNLkgsKsoviUUSs7KLTssvzVHIzS8tyYjligUAMhEd0g==" class="js-render-kroki" data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,W1BpcmF0ZXxleWVDb3VudDogSW50fHJhaWQoKTtwaWxsYWdlKCl8CiAgW2JlYXJkXS0tW3BhcnJvdF0KICBbYmVhcmRdLTo+W2ZvdWwgbW91dGhdCl0=">'
  end

  it 'does not replace nomnoml pre tag with img tag if kroki is disabled' do
    stub_application_setting(kroki_enabled: false)

    # Input rendered from the following Markdown:
    #
    # ```nomnoml
    # [Pirate|eyeCount: Int|raid();pillage()|
    #   [beard]--[parrot]
    #   [beard]-:>[foul mouth]
    # ]
    # ```
    input = <<~INPUT.strip
      <pre data-canonical-lang="nomnoml"><code>[Pirate|eyeCount: Int|raid();pillage()|
        [beard]--[parrot]
        [beard]-:&gt;[foul mouth]
      ]
      </code></pre>
    INPUT
    doc = filter(input)

    expect(doc.to_s).to eq input
  end

  it 'does not replace plantuml pre tag with img tag if both kroki and plantuml are enabled' do
    stub_application_setting(
      kroki_enabled: true,
      kroki_url: "http://localhost:8000",
      plantuml_enabled: true,
      plantuml_url: "http://localhost:8080"
    )

    # Input rendered from the following Markdown:
    #
    # ```plantuml
    # Bob->Alice : hello
    # ```
    input = %(<pre data-canonical-lang="plantuml"><code>Bob-&gt;Alice : hello\n</code></pre>)
    doc = filter(input)

    expect(doc.to_s).to eq input
  end

  it 'adds hidden attribute when content size is large' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")

    text = "[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:&gt;[foul mouth]\n]\n" * 25
    doc = filter(%(<pre data-canonical-lang="nomnoml"><code>#{text}</code></pre>))

    expect(doc.to_s).to start_with '<img src="http://localhost:8000/nomnoml/svg/eNrtzCEOgDAMAEC_V0wysQ9AgkHh8M1EyQosGYw0nSDZ47EInlB74mBJjEKNHppKvaS38yWNMcXODXfKGXfqXDPWwkrIMXgPNzIXCR_rR9hKzfYsVY5gggFttdVWW2211Vbb__YFciTqeA==" hidden="" class="js-render-kroki" data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,W1BpcmF0ZXxleWVDb3VudDog'
  end

  it 'allows the lang attribute on the code tag to support RST files processed by gitlab-markup gem' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")

    # Input rendered from the following Markdown:
    #
    # ```nomnoml
    # [Pirate|eyeCount: Int|raid();pillage()|
    #   [beard]--[parrot]
    #   [beard]-:>[foul mouth]
    # ]
    # ```
    input = <<~INPUT.strip
      <pre><code data-canonical-lang="nomnoml">[Pirate|eyeCount: Int|raid();pillage()|
        [beard]--[parrot]
        [beard]-:&gt;[foul mouth]
      ]
      </code></pre>
    INPUT
    doc = filter(input)

    expect(doc.to_s).to eq '<img src="http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KzhUlCITkpNLEqJ1dWNLkgsKsoviUUSs7KLTssvzVHIzS8tyYjligUAMhEd0g==" class="js-render-kroki" data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,W1BpcmF0ZXxleWVDb3VudDogSW50fHJhaWQoKTtwaWxsYWdlKCl8CiAgW2JlYXJkXS0tW3BhcnJvdF0KICBbYmVhcmRdLTo+W2ZvdWwgbW91dGhdCl0=">'
  end

  it 'verifies diagram type to avoid possible XSS' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")
    doc = filter(%(<a><pre data-canonical-lang='f/" onerror=alert(1) onload=alert(1) '><code data-canonical-lang="wavedrom">xss</code></pre></a>))

    expect(doc.to_s).to eq %(<a><pre data-canonical-lang='f/" onerror=alert(1) onload=alert(1) '><code data-canonical-lang="wavedrom">xss</code></pre></a>)
  end

  it "strips at most one trailing newline from the diagram's source" do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")

    # Input rendered from the following Markdown:
    #
    # ```graphviz
    # digraph { a -> b }
    # // Next line left intentionally blank.
    #
    # ```
    input = %(<pre data-canonical-lang="graphviz"><code>digraph { a -> b }\n// Next line left intentionally blank.\n\n</code></pre>)
    output = '<img src="http://localhost:8000/graphviz/svg/eNpLyUwvSizIUKhWSFTQtVNIUqjl0tdX8EutKFHIycxLVchJTStRyMwrSc0ryczPS8zJqVRIyknMy9bjAgArOBNq" class="js-render-kroki" data-diagram="graphviz" data-diagram-src="data:text/plain;base64,ZGlncmFwaCB7IGEgLT4gYiB9Ci8vIE5leHQgbGluZSBsZWZ0IGludGVudGlvbmFsbHkgYmxhbmsuCg==">'
    doc = filter(input)

    expect(doc.to_s).to eq output
  end

  it_behaves_like 'pipeline timing check'
end

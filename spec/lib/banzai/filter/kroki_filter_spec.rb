# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::KrokiFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'replaces nomnoml pre tag with img tag if kroki is enabled' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")
    doc = filter("<pre data-canonical-lang='nomnoml'><code>[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:>[foul mouth]\n]</code></pre>")

    expect(doc.to_s).to eq '<img src="http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KzhUlCITkpNLEqJ1dWNLkgsKsoviUUSs7KLTssvzVHIzS8tyYjligUAMhEd0g==" class="js-render-kroki" data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,W1BpcmF0ZXxleWVDb3VudDogSW50fHJhaWQoKTtwaWxsYWdlKCl8CiAgW2JlYXJkXS0tW3BhcnJvdF0KICBbYmVhcmRdLTo+W2ZvdWwgbW91dGhdCl0=">'
  end

  it 'replaces nomnoml pre tag with img tag if both kroki and plantuml are enabled' do
    stub_application_setting(
      kroki_enabled: true,
      kroki_url: "http://localhost:8000",
      plantuml_enabled: true,
      plantuml_url: "http://localhost:8080"
    )
    doc = filter("<pre data-canonical-lang='nomnoml'><code>[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:>[foul mouth]\n]</code></pre>")

    expect(doc.to_s).to eq '<img src="http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KzhUlCITkpNLEqJ1dWNLkgsKsoviUUSs7KLTssvzVHIzS8tyYjligUAMhEd0g==" class="js-render-kroki" data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,W1BpcmF0ZXxleWVDb3VudDogSW50fHJhaWQoKTtwaWxsYWdlKCl8CiAgW2JlYXJkXS0tW3BhcnJvdF0KICBbYmVhcmRdLTo+W2ZvdWwgbW91dGhdCl0=">'
  end

  it 'does not replace nomnoml pre tag with img tag if kroki is disabled' do
    stub_application_setting(kroki_enabled: false)
    doc = filter("<pre data-canonical-lang='nomnoml'><code>[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:>[foul mouth]\n]</code></pre>")

    expect(doc.to_s).to eq "<pre data-canonical-lang=\"nomnoml\"><code>[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:&gt;[foul mouth]\n]</code></pre>"
  end

  it 'does not replace plantuml pre tag with img tag if both kroki and plantuml are enabled' do
    stub_application_setting(
      kroki_enabled: true,
      kroki_url: "http://localhost:8000",
      plantuml_enabled: true,
      plantuml_url: "http://localhost:8080"
    )
    doc = filter("<pre data-canonical-lang='plantuml'><code>Bob->Alice : hello</code></pre>")

    expect(doc.to_s).to eq '<pre data-canonical-lang="plantuml"><code>Bob-&gt;Alice : hello</code></pre>'
  end

  it 'adds hidden attribute when content size is large' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")
    text = '[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:>[foul mouth]\n]' * 25
    doc = filter("<pre data-canonical-lang='nomnoml'><code>#{text}</code></pre>")

    expect(doc.to_s).to start_with '<img src="http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KyJyVNQiE5KTSxKidXVjS5ILCrKL4lFFrSyi07LL81RyM0vLckAysRGjxo8avCowaMGjxo8avCowaMGU8lgAE7mIdc=" hidden="" class="js-render-kroki" data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,W1BpcmF0ZXxleWVDb3VudDog'
  end

  it 'allows the lang attribute on the code tag to support RST files processed by gitlab-markup gem' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")
    text = '[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:>[foul mouth]\n]' * 25
    doc = filter("<pre><code data-canonical-lang='nomnoml'>#{text}</code></pre>")

    expect(doc.to_s).to start_with '<img src="http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KyJyVNQiE5KTSxKidXVjS5ILCrKL4lFFrSyi07LL81RyM0vLckAysRGjxo8avCowaMGjxo8avCowaMGU8lgAE7mIdc=" hidden="" class="js-render-kroki" data-diagram="nomnoml" data-diagram-src="data:text/plain;base64,W1BpcmF0ZXxleWVDb3VudDog'
  end

  it 'verifies diagram type to avoid possible XSS' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")
    doc = filter(%(<a><pre data-canonical-lang='f/" onerror=alert(1) onload=alert(1) '><code data-canonical-lang="wavedrom">xss</code></pre></a>))

    expect(doc.to_s).to eq %(<a><pre data-canonical-lang='f/" onerror=alert(1) onload=alert(1) '><code data-canonical-lang="wavedrom">xss</code></pre></a>)
  end

  it_behaves_like 'pipeline timing check'
end

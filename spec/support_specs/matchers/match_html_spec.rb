# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../support/matchers/eq_html'

# rubocop: disable RSpec/ExpectActual -- these *are* the actual values we're testing.
RSpec.describe "eq_html", feature_category: :shared do
  it "normalizes entities" do
    expect(%( x < y + "1"&'2' )).to eq_html(%( x &lt; y + &quot;1&quot;&amp;&#39;2&#x27; ))
  end

  it "doesn't mix up entities" do
    expect(%( <em>no</em> )).not_to eq_html(%( &lt;em&gt;no&lt;/em&gt; ))
  end

  it "normalizes attributes" do
    expect(%( <a id="target" href="#user-content-target" data-tooltip="click &lt;<here&gt;>">Click</a> )).to \
      eq_html(%( <a href='&#x23;user-content-target' id=target data-tooltip='click <<here>>'>Click</a> ))
  end

  it "doesn't confuse similar attributes" do
    expect(%( <a data-tooltip="&amp;lt;">Click</a> )).not_to eq_html(%( <a data-tooltip="&lt;">Click</a> ))
  end
end
# rubocop: enable RSpec/ExpectActual

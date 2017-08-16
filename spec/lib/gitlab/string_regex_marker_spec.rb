require 'spec_helper'

describe Gitlab::StringRegexMarker do
  describe '#mark' do
    let(:raw)  { %{"name": "AFNetworking"} }
    let(:rich) { %{<span class="key">"name"</span><span class="punctuation">: </span><span class="value">"AFNetworking"</span>}.html_safe }
    subject do
      described_class.new(raw, rich).mark(/"[^"]+":\s*"(?<name>[^"]+)"/, group: :name) do |text, left:, right:|
        %{<a href="#">#{text}</a>}
      end
    end

    it 'marks the inline diffs' do
      expect(subject).to eq(%{<span class="key">"name"</span><span class="punctuation">: </span><span class="value">"<a href="#">AFNetworking</a>"</span>})
      expect(subject).to be_html_safe
    end
  end
end

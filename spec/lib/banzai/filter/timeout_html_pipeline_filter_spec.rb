# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TimeoutHtmlPipelineFilter do
  include FilterSpecHelper

  it_behaves_like 'filter timeout' do
    let(:text) { '<p>some text</p>' }
  end

  it 'raises NotImplementedError' do
    expect { filter('test') }.to raise_error NotImplementedError
  end

  context 'when markup_rendering_timeout is disabled' do
    it 'waits until the execution completes' do
      text = '<p>some text</p>'

      stub_feature_flags(markup_rendering_timeout: false)
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:call_with_timeout) do
          text
        end
      end

      expect(Gitlab::RenderTimeout).not_to receive(:timeout)

      result = filter(text)

      expect(result).to eq text
    end
  end
end

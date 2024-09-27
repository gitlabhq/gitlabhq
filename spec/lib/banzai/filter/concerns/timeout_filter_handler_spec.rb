# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::Concerns::TimeoutFilterHandler, feature_category: :markdown do
  include FilterSpecHelper

  context 'when subclassed from HTML filter' do
    before do
      stub_const 'TimeoutTest', Class.new(HTML::Pipeline::Filter)
      TimeoutTest.class_eval { include Banzai::Filter::Concerns::TimeoutFilterHandler }
    end

    let(:described_class) { TimeoutTest }

    it_behaves_like 'a filter timeout' do
      let(:text) { '<p>some text</p>' }
    end

    it 'raises NotImplementedError' do
      expect { filter('test') }.to raise_error NotImplementedError
    end
  end

  context 'when subclassed from Text filter' do
    before do
      stub_const 'TimeoutTest', Class.new(HTML::Pipeline::TextFilter)
      TimeoutTest.class_eval { include Banzai::Filter::Concerns::TimeoutFilterHandler }
    end

    let(:described_class) { TimeoutTest }

    it_behaves_like 'a filter timeout' do
      let(:text) { '<p>some text</p>' }
    end

    it 'raises NotImplementedError' do
      expect { filter('test') }.to raise_error NotImplementedError
    end
  end

  context 'when GITLAB_DISABLE_MARKDOWN_TIMEOUT set' do
    before do
      stub_env('GITLAB_DISABLE_MARKDOWN_TIMEOUT' => '1')
      stub_const 'TimeoutTest', Class.new(HTML::Pipeline::Filter)
      TimeoutTest.class_eval { include Banzai::Filter::Concerns::TimeoutFilterHandler }
    end

    let(:described_class) { TimeoutTest }

    it_behaves_like 'not a filter timeout' do
      let(:text) { '<p>some text</p>' }
    end
  end
end

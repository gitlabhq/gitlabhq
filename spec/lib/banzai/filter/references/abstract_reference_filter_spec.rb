# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::AbstractReferenceFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:doc) { Nokogiri::HTML.fragment('') }
  let_it_be(:filter_instance) { described_class.new(doc, project: project) }

  describe '#data_attributes_for' do
    it 'is not an XSS vector' do
      allow(described_class).to receive(:object_class).and_return(Issue)

      data_attributes = filter_instance.data_attributes_for('xss &lt;img onerror=alert(1) src=x&gt;', project, issue, original_href: '@someone')

      expect(data_attributes[:original]).to eq('xss &lt;img onerror=alert(1) src=x&gt;')
    end

    it 'sets link to true when original_href is present' do
      allow(described_class).to receive(:object_class).and_return(Issue)

      data_attributes = filter_instance.data_attributes_for('content', project, issue, original_href: '@someone')

      expect(data_attributes[:link]).to be(true)
      expect(data_attributes[:original_href]).to eq('@someone')
    end

    it 'sets link to false when original_href is absent' do
      allow(described_class).to receive(:object_class).and_return(Issue)

      data_attributes = filter_instance.data_attributes_for('@someone', project, issue)

      expect(data_attributes[:link]).to be(false)
      expect(data_attributes[:original_href]).to be_nil
    end
  end

  it 'wraps call method with a timeout' do
    allow(described_class).to receive(:object_class).and_return(Issue)
    expect(Gitlab::RenderTimeout).to receive(:timeout).and_call_original

    filter(doc)
  end

  it 'uses gsub_with_limit' do
    allow(described_class).to receive(:object_class).and_return(Issue)
    expect(Gitlab::Utils::Gsub).to receive(:gsub_with_limit).with(anything, anything, limit: Banzai::Filter::FILTER_ITEM_LIMIT).twice.and_call_original

    filter_instance.references_in('text')
  end

  context 'abstract methods' do
    describe '#find_object' do
      it 'raises NotImplementedError' do
        expect { filter_instance.find_object(nil, nil) }.to raise_error(NotImplementedError)
      end
    end

    describe '#url_for_object' do
      it 'raises NotImplementedError' do
        expect { filter_instance.url_for_object(nil, nil) }.to raise_error(NotImplementedError)
      end
    end
  end

  it_behaves_like 'pipeline timing check', context: { project: nil }
  it_behaves_like 'a filter timeout' do
    let(:text) { 'text' }
  end

  describe '#references_in' do
    let(:reference) { %(~"my <label>") }

    let(:fake_label_class) { Class.new }

    before do
      allow(filter_instance).to receive(:object_class).and_return(fake_label_class)
      allow(fake_label_class).to receive_messages(
        name: "fake_label",
        reference_pattern: %r{~"[^"]+"},
        reference_valid?: reference_valid?)
    end

    context 'subclass determines the reference is valid' do
      let(:reference_valid?) { true }

      it_behaves_like 'ReferenceFilter#references_in'
    end

    context 'subclass determines the reference is invalid' do
      let(:reference_valid?) { false }

      it_behaves_like 'ReferenceFilter#references_in' do
        # It should not replace anything.
        let(:expected_replacement) { nil }
      end
    end
  end
end

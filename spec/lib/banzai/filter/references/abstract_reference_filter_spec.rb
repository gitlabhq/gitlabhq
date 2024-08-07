# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::AbstractReferenceFilter, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:doc) { Nokogiri::HTML.fragment('') }
  let_it_be(:filter) { described_class.new(doc, project: project) }

  describe '#data_attributes_for' do
    it 'is not an XSS vector' do
      allow(described_class).to receive(:object_class).and_return(Issue)

      data_attributes = filter.data_attributes_for('xss &lt;img onerror=alert(1) src=x&gt;', project, issue, link_content: true)

      expect(data_attributes[:original]).to eq('xss &amp;lt;img onerror=alert(1) src=x&amp;gt;')
    end
  end

  it 'wraps call method with a timeout' do
    allow(described_class).to receive(:object_class).and_return(Issue)
    expect(Gitlab::RenderTimeout).to receive(:timeout).and_call_original

    filter.call
  end

  context 'abstract methods' do
    describe '#find_object' do
      it 'raises NotImplementedError' do
        expect { filter.find_object(nil, nil) }.to raise_error(NotImplementedError)
      end
    end

    describe '#url_for_object' do
      it 'raises NotImplementedError' do
        expect { filter.url_for_object(nil, nil) }.to raise_error(NotImplementedError)
      end
    end
  end

  it_behaves_like 'pipeline timing check', context: { project: nil }
end

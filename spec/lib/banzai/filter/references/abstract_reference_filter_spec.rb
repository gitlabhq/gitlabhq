# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::AbstractReferenceFilter do
  let_it_be(:project) { create(:project) }

  let(:doc) { Nokogiri::HTML.fragment('') }
  let(:filter) { described_class.new(doc, project: project) }

  describe '#data_attributes_for' do
    let_it_be(:issue) { create(:issue, project: project) }

    it 'is not an XSS vector' do
      allow(described_class).to receive(:object_class).and_return(Issue)

      data_attributes = filter.data_attributes_for('xss &lt;img onerror=alert(1) src=x&gt;', project, issue, link_content: true)

      expect(data_attributes[:original]).to eq('xss &amp;lt;img onerror=alert(1) src=x&amp;gt;')
    end
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
end

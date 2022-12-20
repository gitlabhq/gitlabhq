# frozen_string_literal: true

RSpec.shared_examples 'sanitizable' do |factory, fields|
  let(:attributes) { fields.index_with { input } }

  it 'includes Sanitizable' do
    expect(described_class).to include(Sanitizable)
  end

  fields.each do |field|
    subject do
      record = build(factory, attributes)
      record.valid?

      record.public_send(field)
    end

    describe "##{field}" do
      context 'when input includes javascript tags' do
        let(:input) { 'hello<script>alert(1)</script>' }

        it 'gets sanitized' do
          expect(subject).to eq('hello')
        end
      end
    end

    describe "##{field} validation" do
      context 'when input contains pre-escaped html entities' do
        let_it_be(:input) { '&lt;script&gt;alert(1)&lt;/script&gt;' }

        subject { build(factory, attributes) }

        it 'is not valid', :aggregate_failures do
          expect(subject).not_to be_valid
          expect(subject.errors.details[field].flat_map(&:values)).to include('cannot contain escaped HTML entities')
        end
      end
    end
  end
end

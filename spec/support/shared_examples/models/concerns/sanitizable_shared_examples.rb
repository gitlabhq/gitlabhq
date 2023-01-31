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
          error = 'cannot contain escaped HTML entities'

          expect(subject).not_to be_valid
          expect(subject.errors.details[field].flat_map(&:values)).to contain_exactly(error)
        end
      end

      context 'when it contains a path component' do
        let_it_be(:input) do
          'main../../../../../../api/v4/projects/1/import_project_members/2'
        end

        subject { build(factory, attributes) }

        it 'is not valid', :aggregate_failures do
          error = 'cannot contain a path traversal component'

          expect(subject).not_to be_valid
          expect(subject.errors.details[field].flat_map(&:values)).to contain_exactly(error)
        end
      end
    end
  end
end

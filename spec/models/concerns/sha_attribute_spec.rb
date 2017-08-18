require 'spec_helper'

describe ShaAttribute do
  let(:model) { Class.new { include ShaAttribute } }

  before do
    columns = [
      double(:column, name: 'name', type: :text),
      double(:column, name: 'sha1', type: :binary)
    ]

    allow(model).to receive(:columns).and_return(columns)
  end

  describe '#sha_attribute' do
    context 'when the table exists' do
      before do
        allow(model).to receive(:table_exists?).and_return(true)
      end

      it 'defines a SHA attribute for a binary column' do
        expect(model).to receive(:attribute)
          .with(:sha1, an_instance_of(Gitlab::Database::ShaAttribute))

        model.sha_attribute(:sha1)
      end

      it 'raises ArgumentError when the column type is not :binary' do
        expect { model.sha_attribute(:name) }.to raise_error(ArgumentError)
      end
    end

    context 'when the table does not exist' do
      before do
        allow(model).to receive(:table_exists?).and_return(false)
      end

      it 'does nothing' do
        expect(model).not_to receive(:columns)
        expect(model).not_to receive(:attribute)

        model.sha_attribute(:name)
      end
    end
  end
end

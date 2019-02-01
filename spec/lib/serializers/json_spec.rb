require 'fast_spec_helper'

describe Serializers::JSON do
  describe '.dump' do
    let(:obj) { { key: "value" } }

    subject { described_class.dump(obj) }

    context 'when MySQL is used' do
      before do
        allow(Gitlab::Database).to receive(:adapter_name) { 'mysql2' }
      end

      it 'encodes as string' do
        is_expected.to eq('{"key":"value"}')
      end
    end

    context 'when PostgreSQL is used' do
      before do
        allow(Gitlab::Database).to receive(:adapter_name) { 'postgresql' }
      end

      it 'returns a hash' do
        is_expected.to eq(obj)
      end
    end
  end

  describe '.load' do
    let(:data_string) { '{"key":"value","variables":[{"key":"VAR1","value":"VALUE1"}]}' }
    let(:data_hash) { JSON.parse(data_string) }

    shared_examples 'having consistent accessor' do
      it 'allows to access with symbols' do
        expect(subject[:key]).to eq('value')
        expect(subject[:variables].first[:key]).to eq('VAR1')
      end

      it 'allows to access with strings' do
        expect(subject["key"]).to eq('value')
        expect(subject["variables"].first["key"]).to eq('VAR1')
      end
    end

    context 'when MySQL is used' do
      before do
        allow(Gitlab::Database).to receive(:adapter_name) { 'mysql2' }
      end

      context 'when loading a string' do
        subject { described_class.load(data_string) }

        it 'decodes a string' do
          is_expected.to be_a(Hash)
        end

        it_behaves_like 'having consistent accessor'
      end

      context 'when loading a different type' do
        subject { described_class.load({ key: 'hash' }) }

        it 'raises an exception' do
          expect { subject }.to raise_error(TypeError)
        end
      end

      context 'when loading a nil' do
        subject { described_class.load(nil) }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end

    context 'when PostgreSQL is used' do
      before do
        allow(Gitlab::Database).to receive(:adapter_name) { 'postgresql' }
      end

      context 'when loading a hash' do
        subject { described_class.load(data_hash) }

        it 'decodes a string' do
          is_expected.to be_a(Hash)
        end

        it_behaves_like 'having consistent accessor'
      end

      context 'when loading a nil' do
        subject { described_class.load(nil) }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end
  end
end

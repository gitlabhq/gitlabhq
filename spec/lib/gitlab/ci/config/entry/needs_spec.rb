# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::Ci::Config::Entry::Needs do
  subject(:needs) { described_class.new(config) }

  before do
    needs.metadata[:allowed_needs] = %i[job]
  end

  describe 'validations' do
    before do
      needs.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { ['job_name'] }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end
    end

    context 'when config value has wrong type' do
      let(:config) { 123 }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about incorrect type' do
          expect(needs.errors)
            .to include('needs config can only be a hash or an array')
        end
      end
    end

    context 'when wrong needs type is used' do
      let(:config) { [123] }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about incorrect type' do
          expect(needs.errors).to contain_exactly(
            'need has an unsupported type')
        end
      end
    end

    context 'when wrong needs type is used' do
      let(:config) { [{ job: 'job_name', artifacts: true, some: :key }] }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about incorrect type' do
          expect(needs.errors).to contain_exactly(
            'need config contains unknown keys: some')
        end
      end
    end
  end

  describe '.compose!' do
    shared_examples 'entry with descendant nodes' do
      describe '#descendants' do
        it 'creates valid descendant nodes' do
          expect(needs.descendants.count).to eq 2
          expect(needs.descendants)
            .to all(be_an_instance_of(::Gitlab::Ci::Config::Entry::Need))
        end
      end
    end

    context 'when valid job entries composed' do
      let(:config) { %w[first_job_name second_job_name] }

      before do
        needs.compose!
      end

      describe '#value' do
        it 'returns key value' do
          expect(needs.value).to eq(
            job: [
              { name: 'first_job_name',  artifacts: true },
              { name: 'second_job_name', artifacts: true }
            ]
          )
        end
      end

      it_behaves_like 'entry with descendant nodes'
    end

    context 'with complex job entries composed' do
      let(:config) do
        [
          { job: 'first_job_name',  artifacts: true },
          { job: 'second_job_name', artifacts: false }
        ]
      end

      before do
        needs.compose!
      end

      describe '#value' do
        it 'returns key value' do
          expect(needs.value).to eq(
            job: [
              { name: 'first_job_name',  artifacts: true },
              { name: 'second_job_name', artifacts: false }
            ]
          )
        end
      end

      it_behaves_like 'entry with descendant nodes'
    end

    context 'with mixed job entries composed' do
      let(:config) do
        [
          'first_job_name',
          { job: 'second_job_name', artifacts: false }
        ]
      end

      before do
        needs.compose!
      end

      describe '#value' do
        it 'returns key value' do
          expect(needs.value).to eq(
            job: [
              { name: 'first_job_name',  artifacts: true },
              { name: 'second_job_name', artifacts: false }
            ]
          )
        end
      end

      it_behaves_like 'entry with descendant nodes'
    end

    context 'with empty config' do
      let(:config) do
        []
      end

      before do
        needs.compose!
      end

      describe '#value' do
        it 'returns empty value' do
          expect(needs.value).to eq({})
        end
      end
    end
  end
end

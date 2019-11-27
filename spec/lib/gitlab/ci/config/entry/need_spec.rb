# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::Ci::Config::Entry::Need do
  subject(:need) { described_class.new(config) }

  shared_examples 'job type' do
    describe '#type' do
      subject(:need_type) { need.type }

      it { is_expected.to eq(:job) }
    end
  end

  context 'with simple config' do
    context 'when job is specified' do
      let(:config) { 'job_name' }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: true)
        end
      end

      it_behaves_like 'job type'
    end

    context 'when need is empty' do
      let(:config) { '' }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about an empty config' do
          expect(need.errors)
            .to contain_exactly("job string config can't be blank")
        end
      end

      it_behaves_like 'job type'
    end
  end

  context 'with complex config' do
    context 'with job name and artifacts true' do
      let(:config) { { job: 'job_name', artifacts: true } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: true)
        end
      end

      it_behaves_like 'job type'
    end

    context 'with job name and artifacts false' do
      let(:config) { { job: 'job_name', artifacts: false } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: false)
        end
      end

      it_behaves_like 'job type'
    end

    context 'with job name and artifacts nil' do
      let(:config) { { job: 'job_name', artifacts: nil } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: true)
        end
      end

      it_behaves_like 'job type'
    end

    context 'without artifacts key' do
      let(:config) { { job: 'job_name' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: true)
        end
      end

      it_behaves_like 'job type'
    end

    context 'when job name is empty' do
      let(:config) { { job: '', artifacts: true } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about an empty config' do
          expect(need.errors)
            .to contain_exactly("job hash job can't be blank")
        end
      end

      it_behaves_like 'job type'
    end

    context 'when job name is not a string' do
      let(:config) { { job: :job_name, artifacts: false } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about job type' do
          expect(need.errors)
            .to contain_exactly('job hash job should be a string')
        end
      end

      it_behaves_like 'job type'
    end

    context 'when job has unknown keys' do
      let(:config) { { job: 'job_name', artifacts: false, some: :key } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about job type' do
          expect(need.errors)
            .to contain_exactly('job hash config contains unknown keys: some')
        end
      end

      it_behaves_like 'job type'
    end
  end

  context 'when need config is not a string or a hash' do
    let(:config) { :job_name }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about job type' do
        expect(need.errors)
          .to contain_exactly('unknown strategy has an unsupported type')
      end
    end
  end
end

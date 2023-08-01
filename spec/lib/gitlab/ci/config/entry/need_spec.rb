# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Entry::Need, feature_category: :pipeline_composition do
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
          expect(need.value).to eq(name: 'job_name', artifacts: true, optional: false)
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
          expect(need.value).to eq(name: 'job_name', artifacts: true, optional: false)
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
          expect(need.value).to eq(name: 'job_name', artifacts: false, optional: false)
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
          expect(need.value).to eq(name: 'job_name', artifacts: true, optional: false)
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
          expect(need.value).to eq(name: 'job_name', artifacts: true, optional: false)
        end
      end

      it_behaves_like 'job type'
    end

    context 'with job name and optional true' do
      let(:config) { { job: 'job_name', optional: true } }

      it { is_expected.to be_valid }

      it_behaves_like 'job type'

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: true, optional: true)
        end
      end
    end

    context 'with job name and optional false' do
      let(:config) { { job: 'job_name', optional: false } }

      it { is_expected.to be_valid }

      it_behaves_like 'job type'

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: true, optional: false)
        end
      end
    end

    context 'with job name and optional nil' do
      let(:config) { { job: 'job_name', optional: nil } }

      it { is_expected.to be_valid }

      it_behaves_like 'job type'

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: true, optional: false)
        end
      end
    end

    context 'without optional key' do
      let(:config) { { job: 'job_name' } }

      it { is_expected.to be_valid }

      it_behaves_like 'job type'

      describe '#value' do
        it 'returns job needs configuration' do
          expect(need.value).to eq(name: 'job_name', artifacts: true, optional: false)
        end
      end
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

    context 'when parallel:matrix has a value' do
      before do
        need.compose!
      end

      context 'and it is a string value' do
        let(:config) do
          { job: 'job_name', parallel: { matrix: [{ platform: 'p1', stack: 's1' }] } }
        end

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          it 'returns job needs configuration' do
            expect(need.value).to eq(
              name: 'job_name',
              artifacts: true,
              optional: false,
              parallel: { matrix: [{ "platform" => ['p1'], "stack" => ['s1'] }] }
            )
          end
        end

        it_behaves_like 'job type'
      end

      context 'and it is an array value' do
        let(:config) do
          { job: 'job_name', parallel: { matrix: [{ platform: %w[p1 p2], stack: %w[s1 s2] }] } }
        end

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          it 'returns job needs configuration' do
            expect(need.value).to eq(
              name: 'job_name',
              artifacts: true,
              optional: false,
              parallel: { matrix: [{ 'platform' => %w[p1 p2], 'stack' => %w[s1 s2] }] }
            )
          end
        end

        it_behaves_like 'job type'
      end

      context 'and it is a both an array and string value' do
        let(:config) do
          { job: 'job_name', parallel: { matrix: [{ platform: %w[p1 p2], stack: 's1' }] } }
        end

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          it 'returns job needs configuration' do
            expect(need.value).to eq(
              name: 'job_name',
              artifacts: true,
              optional: false,
              parallel: { matrix: [{ 'platform' => %w[p1 p2], 'stack' => ['s1'] }] }
            )
          end
        end

        it_behaves_like 'job type'
      end
    end
  end

  context 'with cross pipeline artifacts needs' do
    context 'when pipeline is provided' do
      context 'when job is provided' do
        let(:config) { { job: 'job_name', pipeline: '$THE_PIPELINE_ID' } }

        it { is_expected.to be_valid }

        it 'sets artifacts:true by default' do
          expect(need.value).to eq(job: 'job_name', pipeline: '$THE_PIPELINE_ID', artifacts: true)
        end

        it 'sets the type as cross_dependency' do
          expect(need.type).to eq(:cross_dependency)
        end
      end

      context 'when artifacts is provided' do
        let(:config) { { job: 'job_name', pipeline: '$THE_PIPELINE_ID', artifacts: false } }

        it { is_expected.to be_valid }

        it 'returns the correct value' do
          expect(need.value).to eq(job: 'job_name', pipeline: '$THE_PIPELINE_ID', artifacts: false)
        end
      end
    end

    context 'when config contains not allowed keys' do
      let(:config) { { job: 'job_name', pipeline: '$THE_PIPELINE_ID', something: 'else' } }

      it { is_expected.not_to be_valid }

      it 'returns an error' do
        expect(need.errors)
          .to contain_exactly('cross pipeline dependency config contains unknown keys: something')
      end
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

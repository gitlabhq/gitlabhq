# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Entry::Needs, feature_category: :pipeline_composition do
  subject(:needs) { described_class.new(config) }

  before do
    needs.metadata[:allowed_needs] = %i[job cross_dependency]
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

    context 'when config has disallowed keys' do
      let(:config) { ['some_value'] }

      before do
        needs.metadata[:allowed_needs] = %i[cross_dependency]
        needs.compose!
      end

      describe '#valid?' do
        it 'returns invalid' do
          expect(needs.valid?).to be_falsey
        end
      end

      describe '#errors' do
        it 'returns invalid types error' do
          expect(needs.errors).to include('needs config uses invalid types: job')
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

    context 'when needs value is a hash' do
      context 'with a job value' do
        let(:config) do
          { job: 'job_name' }
        end

        describe '#valid?' do
          it { is_expected.to be_valid }
        end
      end

      context 'with a parallel value that is a numeric value' do
        let(:config) do
          { job: 'job_name', parallel: 2 }
        end

        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          it 'returns errors about number values being invalid for needs:parallel' do
            expect(needs.errors).to match_array(["needs config cannot use \"parallel: <number>\"."])
          end
        end
      end
    end

    context 'when needs:parallel value is incorrect' do
      context 'with a keyword that is not "matrix"' do
        let(:config) do
          [
            { job: 'job_name', parallel: { not_matrix: [{ one: 'aaa', two: 'bbb' }] } }
          ]
        end

        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          it 'returns errors about incorrect matrix keyword' do
            expect(needs.errors).to match_array([
              'need:parallel config contains unknown keys: not_matrix',
              'need:parallel config missing required keys: matrix'
            ])
          end
        end
      end

      context 'with a number value' do
        let(:config) { [{ job: 'job_name', parallel: 2 }] }

        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          it 'returns errors about number values being invalid for needs:parallel' do
            expect(needs.errors).to match_array(["needs config cannot use \"parallel: <number>\"."])
          end
        end
      end
    end

    context 'when needs:parallel:matrix value is empty' do
      let(:config) { [{ job: 'job_name', parallel: { matrix: {} } }] }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about incorrect type' do
          expect(needs.errors).to contain_exactly(
            'need:parallel:matrix config should be an array of hashes')
        end
      end
    end

    context 'when needs:parallel:matrix value is incorrect' do
      let(:config) { [{ job: 'job_name', parallel: { matrix: 'aaa' } }] }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about incorrect type' do
          expect(needs.errors).to contain_exactly(
            'need:parallel:matrix config should be an array of hashes')
        end
      end
    end

    context 'when needs:parallel:matrix value is correct' do
      context 'with a simple config' do
        let(:config) do
          [
            { job: 'job_name', parallel: { matrix: [{ A: 'a1', B: 'b1' }] } }
          ]
        end

        describe '#valid?' do
          it { is_expected.to be_valid }
        end
      end

      context 'with a complex config' do
        let(:config) do
          [
            {
              job: 'job_name1',
              artifacts: true,
              parallel: { matrix: [{ A: %w[a1 a2], B: %w[b1 b2 b3], C: %w[c1 c2] }] }
            },
            {
              job: 'job_name2',
              parallel: {
                matrix: [
                  { A: %w[a1 a2], D: %w[d1 d2] },
                  { E: %w[e1 e2], F: ['f1'] },
                  { C: %w[c1 c2 c3], G: %w[g1 g2], H: ['h1'] }
                ]
              }
            }
          ]
        end

        describe '#valid?' do
          it { is_expected.to be_valid }
        end
      end
    end

    context 'with too many cross pipeline dependencies' do
      let(:limit) { described_class::NEEDS_CROSS_PIPELINE_DEPENDENCIES_LIMIT }

      let(:config) do
        Array.new(limit.next) do |index|
          { pipeline: "$UPSTREAM_PIPELINE_#{index}", job: 'job-1' }
        end
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about incorrect type' do
          expect(needs.errors).to contain_exactly(
            "needs config must be less than or equal to #{limit}")
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
              { name: 'first_job_name',  artifacts: true, optional: false },
              { name: 'second_job_name', artifacts: true, optional: false }
            ]
          )
        end
      end

      it_behaves_like 'entry with descendant nodes'
    end

    context 'with complex job entries composed' do
      let(:config) do
        [
          { job: 'first_job_name',  artifacts: true, optional: false },
          { job: 'second_job_name', artifacts: false, optional: false }
        ]
      end

      before do
        needs.compose!
      end

      describe '#value' do
        it 'returns key value' do
          expect(needs.value).to eq(
            job: [
              { name: 'first_job_name',  artifacts: true, optional: false },
              { name: 'second_job_name', artifacts: false, optional: false }
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
              { name: 'first_job_name',  artifacts: true, optional: false },
              { name: 'second_job_name', artifacts: false, optional: false }
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

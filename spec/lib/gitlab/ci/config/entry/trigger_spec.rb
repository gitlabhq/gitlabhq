# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Trigger do
  subject { described_class.new(config) }

  context 'when trigger config is a non-empty string' do
    let(:config) { 'some/project' }

    describe '#valid?' do
      it { is_expected.to be_valid }
    end

    describe '#value' do
      it 'returns a trigger configuration hash' do
        expect(subject.value).to eq(project: 'some/project')
      end
    end
  end

  context 'when trigger config an empty string' do
    let(:config) { '' }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'returns an error about an empty config' do
        expect(subject.errors.first)
          .to match /config can't be blank/
      end
    end
  end

  context 'when trigger is a hash' do
    context 'when branch is provided' do
      let(:config) { { project: 'some/project', branch: 'feature' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns a trigger configuration hash' do
          expect(subject.value)
            .to eq(project: 'some/project', branch: 'feature')
        end
      end
    end

    context 'when strategy is provided' do
      context 'when strategy is depend' do
        let(:config) { { project: 'some/project', strategy: 'depend' } }

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          it 'returns a trigger configuration hash' do
            expect(subject.value)
              .to eq(project: 'some/project', strategy: 'depend')
          end
        end
      end

      context 'when strategy is invalid' do
        let(:config) { { project: 'some/project', strategy: 'notdepend' } }

        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          it 'returns an error about unknown config key' do
            expect(subject.errors.first)
              .to match /trigger strategy should be depend/
          end
        end
      end
    end

    describe '#include' do
      context 'with simple include' do
        let(:config) { { include: 'path/to/config.yml' } }

        it { is_expected.to be_valid }

        it 'returns a trigger configuration hash' do
          expect(subject.value).to eq(include: 'path/to/config.yml' )
        end
      end

      context 'with project' do
        let(:config) { { project: 'some/project', include: 'path/to/config.yml' } }

        it { is_expected.not_to be_valid }

        it 'returns an error' do
          expect(subject.errors.first)
            .to match /config contains unknown keys: project/
        end
      end

      context 'with branch' do
        let(:config) { { branch: 'feature', include: 'path/to/config.yml' } }

        it { is_expected.not_to be_valid }

        it 'returns an error' do
          expect(subject.errors.first)
            .to match /config contains unknown keys: branch/
        end
      end
    end

    context 'when config contains unknown keys' do
      let(:config) { { project: 'some/project', unknown: 123 } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error about unknown config key' do
          expect(subject.errors.first)
            .to match /config contains unknown keys: unknown/
        end
      end
    end
  end

  context 'when trigger configuration is not valid' do
    context 'when branch is not provided' do
      let(:config) { 123 }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error message' do
          expect(subject.errors.first)
            .to match /has to be either a string or a hash/
        end
      end
    end
  end
end

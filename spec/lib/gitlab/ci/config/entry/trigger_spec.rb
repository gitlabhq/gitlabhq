# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Trigger, feature_category: :pipeline_composition do
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
          .to match(/config can't be blank/)
      end
    end
  end

  context 'when trigger is a hash - cross-project' do
    context 'when project is a string' do
      context 'when project is a non-empty string' do
        let(:config) { { project: 'some/project' } }

        it 'is valid' do
          expect(subject).to be_valid
        end
      end

      context 'when project is an empty string' do
        let(:config) { { project: '' } }

        it 'returns error' do
          expect(subject).not_to be_valid
          expect(subject.errors.first)
            .to match(/project can't be blank/)
        end
      end
    end

    context 'when project is not a string' do
      context 'when project is an array' do
        let(:config) { { project: ['some/project'] } }

        it 'returns error' do
          expect(subject).not_to be_valid
          expect(subject.errors.first)
            .to match(/should be a string/)
        end
      end

      context 'when project is a boolean' do
        let(:config) { { project: true } }

        it 'returns error' do
          expect(subject).not_to be_valid
          expect(subject.errors.first)
            .to match(/should be a string/)
        end
      end
    end

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
              .to match(/trigger strategy should be depend/)
          end
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
            .to match(/config contains unknown keys: unknown/)
        end
      end
    end

    context 'with forward' do
      let(:config) { { project: 'some/project', forward: { pipeline_variables: true } } }

      before do
        subject.compose!
      end

      it { is_expected.to be_valid }

      it 'returns a trigger configuration hash' do
        expect(subject.value).to eq(
          project: 'some/project', forward: { pipeline_variables: true }
        )
      end
    end
  end

  context 'when trigger is a hash - parent-child' do
    context 'with simple include' do
      let(:config) { { include: 'path/to/config.yml' } }

      it { is_expected.to be_valid }

      it 'returns a trigger configuration hash' do
        expect(subject.value).to eq(include: 'path/to/config.yml')
      end
    end

    context 'with project' do
      let(:config) { { project: 'some/project', include: 'path/to/config.yml' } }

      it { is_expected.not_to be_valid }

      it 'returns an error' do
        expect(subject.errors.first)
          .to match(/config contains unknown keys: project/)
      end
    end

    context 'with branch' do
      let(:config) { { branch: 'feature', include: 'path/to/config.yml' } }

      it { is_expected.not_to be_valid }

      it 'returns an error' do
        expect(subject.errors.first)
          .to match(/config contains unknown keys: branch/)
      end
    end

    context 'with forward' do
      let(:config) { { include: 'path/to/config.yml', forward: { yaml_variables: false } } }

      before do
        subject.compose!
      end

      it { is_expected.to be_valid }

      it 'returns a trigger configuration hash' do
        expect(subject.value).to eq(
          include: 'path/to/config.yml', forward: { yaml_variables: false }
        )
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
            .to match(/has to be either a string or a hash/)
        end
      end
    end
  end
end

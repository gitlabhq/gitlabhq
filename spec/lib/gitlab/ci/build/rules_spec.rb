# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules, feature_category: :pipeline_composition do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:ci_build) { build(:ci_build, pipeline: pipeline) }

  let(:seed) do
    double('build seed',
      to_resource: ci_build,
      variables_hash: ci_build.scoped_variables.to_hash
    )
  end

  let(:rules) { described_class.new(rule_list, default_when: 'on_success') }

  describe '.new' do
    let(:rules_ivar)   { rules.instance_variable_get :@rule_list }
    let(:default_when) { rules.instance_variable_get :@default_when }

    context 'with no rules' do
      let(:rule_list) { [] }

      it 'sets @rule_list to an empty array' do
        expect(rules_ivar).to eq([])
      end

      it 'sets @default_when to "on_success"' do
        expect(default_when).to eq('on_success')
      end
    end

    context 'with one rule' do
      let(:rule_list) { [{ if: '$VAR == null', when: 'always' }] }

      it 'sets @rule_list to an array of a single rule' do
        expect(rules_ivar).to be_an(Array)
      end

      it 'sets @default_when to "on_success"' do
        expect(default_when).to eq('on_success')
      end
    end

    context 'with multiple rules' do
      let(:rule_list) do
        [
          { if: '$VAR == null', when: 'always' },
          { if: '$VAR == null', when: 'always' }
        ]
      end

      it 'sets @rule_list to an array of a single rule' do
        expect(rules_ivar).to be_an(Array)
      end

      it 'sets @default_when to "on_success"' do
        expect(default_when).to eq('on_success')
      end
    end

    context 'with a specified default when:' do
      let(:rule_list) { [{ if: '$VAR == null', when: 'always' }] }
      let(:rules)     { described_class.new(rule_list, default_when: 'manual') }

      it 'sets @rule_list to an array of a single rule' do
        expect(rules_ivar).to be_an(Array)
      end

      it 'sets @default_when to "manual"' do
        expect(default_when).to eq('manual')
      end
    end
  end

  describe '#evaluate' do
    subject { rules.evaluate(pipeline, seed) }

    context 'with nil rules' do
      let(:rule_list) { nil }

      it { is_expected.to eq(described_class::Result.new(when: 'on_success')) }

      context 'and when:manual set as the default' do
        let(:rules) { described_class.new(rule_list, default_when: 'manual') }

        it { is_expected.to eq(described_class::Result.new(when: 'manual')) }
      end
    end

    context 'with no rules' do
      let(:rule_list) { [] }

      it { is_expected.to eq(described_class::Result.new(when: 'never')) }

      context 'and when:manual set as the default' do
        let(:rules) { described_class.new(rule_list, default_when: 'manual') }

        it { is_expected.to eq(described_class::Result.new(when: 'never')) }
      end
    end

    context 'with one rule without any clauses' do
      let(:rule_list) { [{ when: 'manual', allow_failure: true }] }

      it { is_expected.to eq(described_class::Result.new(when: 'manual', allow_failure: true)) }
    end

    context 'with one matching rule' do
      let(:rule_list) { [{ if: '$VAR == null', when: 'always' }] }

      it { is_expected.to eq(described_class::Result.new(when: 'always')) }
    end

    context 'with two matching rules' do
      let(:rule_list) do
        [
          { if: '$VAR == null', when: 'delayed', start_in: '1 day' },
          { if: '$VAR == null', when: 'always' }
        ]
      end

      it 'returns the value of the first matched rule in the list' do
        expect(subject).to eq(described_class::Result.new(when: 'delayed', start_in: '1 day'))
      end
    end

    context 'with a non-matching and matching rule' do
      let(:rule_list) do
        [
          { if: '$VAR =! null', when: 'delayed', start_in: '1 day' },
          { if: '$VAR == null', when: 'always' }
        ]
      end

      it { is_expected.to eq(described_class::Result.new(when: 'always')) }
    end

    context 'with a matching and non-matching rule' do
      let(:rule_list) do
        [
          { if: '$VAR == null', when: 'delayed', start_in: '1 day' },
          { if: '$VAR != null', when: 'always' }
        ]
      end

      it { is_expected.to eq(described_class::Result.new(when: 'delayed', start_in: '1 day')) }
    end

    context 'with non-matching rules' do
      let(:rule_list) do
        [
          { if: '$VAR != null', when: 'delayed', start_in: '1 day' },
          { if: '$VAR != null', when: 'always' }
        ]
      end

      it { is_expected.to eq(described_class::Result.new(when: 'never')) }

      context 'and when:manual set as the default' do
        let(:rules) { described_class.new(rule_list, default_when: 'manual') }

        it 'does not return the default when:' do
          expect(subject).to eq(described_class::Result.new(when: 'never'))
        end
      end
    end

    context 'with only allow_failure' do
      context 'with matching rule' do
        let(:rule_list) { [{ if: '$VAR == null', allow_failure: true }] }

        it { is_expected.to eq(described_class::Result.new(when: 'on_success', allow_failure: true)) }
      end

      context 'with non-matching rule' do
        let(:rule_list) { [{ if: '$VAR != null', allow_failure: true }] }

        it { is_expected.to eq(described_class::Result.new(when: 'never')) }
      end
    end

    context 'with needs' do
      context 'when single need is specified' do
        let(:rule_list) do
          [{ if: '$VAR == null', needs: [{ name: 'test', artifacts: true, optional: false }] }]
        end

        it do
          is_expected.to eq(described_class::Result.new(
            when: 'on_success',
            needs: [{ name: 'test',
                      artifacts: true,
                      optional: false }]
          ))
        end
      end

      context 'when multiple needs are specified' do
        let(:rule_list) do
          [{ if: '$VAR == null',
             needs: [{ name: 'test', artifacts: true, optional: false },
               { name: 'rspec', artifacts: true, optional: false }] }]
        end

        it do
          is_expected.to eq(described_class::Result.new(
            when: 'on_success',
            needs: [{ name: 'test',
                      artifacts: true,
                      optional: false },
              { name: 'rspec',
                artifacts: true,
                optional: false }]))
        end
      end

      context 'when there are no needs specified' do
        let(:rule_list) { [{ if: '$VAR == null' }] }

        it do
          is_expected.to eq(described_class::Result.new(when: 'on_success'))
        end
      end

      context 'when need is specified with additional attibutes' do
        let(:rule_list) do
          [{ if: '$VAR == null', needs: [{
            artifacts: false,
            name: 'test',
            optional: true,
            when: 'never'
          }] }]
        end

        it do
          is_expected.to eq(
            described_class::Result.new(
              when: 'on_success',
              needs: [{ artifacts: false,
                        name: 'test',
                        optional: true,
                        when: 'never' }]))
        end
      end
    end

    context 'with variables' do
      context 'with matching rule' do
        let(:rule_list) { [{ if: '$VAR == null', variables: { MY_VAR: 'my var' } }] }

        it { is_expected.to eq(described_class::Result.new(when: 'on_success', variables: { MY_VAR: 'my var' })) }
      end
    end

    context 'with auto_cancel' do
      context 'with matching rule' do
        let(:rule_list) { [{ if: '$VAR == null', auto_cancel: { on_new_commit: 'interruptible' } }] }

        it do
          is_expected.to eq(
            described_class::Result.new(when: 'on_success', auto_cancel: { on_new_commit: 'interruptible' })
          )
        end
      end
    end

    context 'with interruptible' do
      context 'with matching rule' do
        let(:rule_list) { [{ if: '$VAR == null', interruptible: true }] }

        it { is_expected.to eq(described_class::Result.new(when: 'on_success', interruptible: true)) }
      end
    end

    context 'with a regexp variable matching rule' do
      let(:rule_list) { [{ if: '"abcde" =~ $pattern' }] }

      before do
        allow(ci_build).to receive(:scoped_variables).and_return(
          Gitlab::Ci::Variables::Collection.new
            .append(key: 'pattern', value: '/^ab.*/', public: true)
        )
      end

      it { is_expected.to eq(described_class::Result.new(when: 'on_success')) }
    end
  end

  describe 'Gitlab::Ci::Build::Rules::Result' do
    let(:when_value) { 'on_success' }
    let(:start_in) { nil }
    let(:allow_failure) { nil }
    let(:variables) { nil }
    let(:needs) { nil }
    let(:interruptible) { nil }

    subject(:result) do
      Gitlab::Ci::Build::Rules::Result.new(
        when: when_value,
        start_in: start_in,
        allow_failure: allow_failure,
        variables: variables,
        needs: needs,
        interruptible: interruptible)
    end

    describe '#build_attributes' do
      subject(:build_attributes) do
        result.build_attributes
      end

      it 'compacts nil values' do
        is_expected.to eq(options: {}, when: 'on_success')
      end

      context 'scheduling_type' do
        context 'when rules have needs' do
          context 'single need' do
            let(:needs) do
              { job: [{ name: 'test' }] }
            end

            it 'saves needs' do
              expect(subject[:needs_attributes]).to eq([{ name: "test" }])
            end

            it 'adds schedule type to the build_attributes' do
              expect(subject[:scheduling_type]).to eq(:dag)
            end
          end

          context 'multiple needs' do
            let(:needs) do
              { job: [{ name: 'test' }, { name: 'test_2', artifacts: true, optional: false }] }
            end

            it 'saves needs' do
              expect(subject[:needs_attributes]).to match_array([{ name: "test" },
                { name: 'test_2', artifacts: true, optional: false }])
            end

            it 'adds schedule type to the build_attributes' do
              expect(subject[:scheduling_type]).to eq(:dag)
            end
          end
        end

        context 'when rules do not have needs' do
          it 'does not add schedule type to the build_attributes' do
            expect(subject.key?(:scheduling_type)).to be_falsy
          end
        end
      end
    end

    describe '#pass?' do
      context "'when' is 'never'" do
        let!(:when_value) { 'never' }

        it 'returns false' do
          expect(result.pass?).to eq(false)
        end
      end

      context "'when' is 'on_success'" do
        let!(:when_value) { 'on_success' }

        it 'returns true' do
          expect(result.pass?).to eq(true)
        end
      end
    end
  end
end

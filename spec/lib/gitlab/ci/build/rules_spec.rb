# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules do
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

      it { is_expected.to eq(described_class::Result.new('on_success')) }

      context 'and when:manual set as the default' do
        let(:rules) { described_class.new(rule_list, default_when: 'manual') }

        it { is_expected.to eq(described_class::Result.new('manual')) }
      end
    end

    context 'with no rules' do
      let(:rule_list) { [] }

      it { is_expected.to eq(described_class::Result.new('never')) }

      context 'and when:manual set as the default' do
        let(:rules) { described_class.new(rule_list, default_when: 'manual') }

        it { is_expected.to eq(described_class::Result.new('never')) }
      end
    end

    context 'with one rule without any clauses' do
      let(:rule_list) { [{ when: 'manual', allow_failure: true }] }

      it { is_expected.to eq(described_class::Result.new('manual', nil, true, nil)) }
    end

    context 'with one matching rule' do
      let(:rule_list) { [{ if: '$VAR == null', when: 'always' }] }

      it { is_expected.to eq(described_class::Result.new('always')) }
    end

    context 'with two matching rules' do
      let(:rule_list) do
        [
          { if: '$VAR == null', when: 'delayed', start_in: '1 day' },
          { if: '$VAR == null', when: 'always' }
        ]
      end

      it 'returns the value of the first matched rule in the list' do
        expect(subject).to eq(described_class::Result.new('delayed', '1 day'))
      end
    end

    context 'with a non-matching and matching rule' do
      let(:rule_list) do
        [
          { if: '$VAR =! null', when: 'delayed', start_in: '1 day' },
          { if: '$VAR == null', when: 'always' }
        ]
      end

      it { is_expected.to eq(described_class::Result.new('always')) }
    end

    context 'with a matching and non-matching rule' do
      let(:rule_list) do
        [
          { if: '$VAR == null', when: 'delayed', start_in: '1 day' },
          { if: '$VAR != null', when: 'always' }
        ]
      end

      it { is_expected.to eq(described_class::Result.new('delayed', '1 day')) }
    end

    context 'with non-matching rules' do
      let(:rule_list) do
        [
          { if: '$VAR != null', when: 'delayed', start_in: '1 day' },
          { if: '$VAR != null', when: 'always' }
        ]
      end

      it { is_expected.to eq(described_class::Result.new('never')) }

      context 'and when:manual set as the default' do
        let(:rules) { described_class.new(rule_list, default_when: 'manual') }

        it 'does not return the default when:' do
          expect(subject).to eq(described_class::Result.new('never'))
        end
      end
    end

    context 'with only allow_failure' do
      context 'with matching rule' do
        let(:rule_list) { [{ if: '$VAR == null', allow_failure: true }] }

        it { is_expected.to eq(described_class::Result.new('on_success', nil, true, nil)) }
      end

      context 'with non-matching rule' do
        let(:rule_list) { [{ if: '$VAR != null', allow_failure: true }] }

        it { is_expected.to eq(described_class::Result.new('never')) }
      end
    end

    context 'with needs' do
      context 'when single needs is specified' do
        let(:rule_list) do
          [{ if: '$VAR == null', needs: [{ name: 'test', artifacts: true, optional: false }] }]
        end

        it {
          is_expected.to eq(described_class::Result.new('on_success', nil, nil, nil,
            [{ name: 'test', artifacts: true, optional: false }], nil))
        }
      end

      context 'when multiple needs are specified' do
        let(:rule_list) do
          [{ if: '$VAR == null',
             needs: [{ name: 'test', artifacts: true, optional: false },
               { name: 'rspec', artifacts: true, optional: false }] }]
        end

        it {
          is_expected.to eq(described_class::Result.new('on_success', nil, nil, nil,
            [{ name: 'test', artifacts: true, optional: false },
              { name: 'rspec', artifacts: true, optional: false }], nil))
        }
      end

      context 'when there are no needs specified' do
        let(:rule_list) { [{ if: '$VAR == null' }] }

        it { is_expected.to eq(described_class::Result.new('on_success', nil, nil, nil, nil, nil)) }
      end

      context 'when need is specified with additional attibutes' do
        let(:rule_list) do
          [{ if: '$VAR == null', needs: [{
            artifacts: true,
            name: 'test',
            optional: false,
            when: 'never'
          }] }]
        end

        it {
          is_expected.to eq(
            described_class::Result.new('on_success', nil, nil, nil,
              [{ artifacts: true, name: 'test', optional: false, when: 'never' }], nil))
        }
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(introduce_rules_with_needs: false)
        end

        context 'with needs' do
          context 'when single needs is specified' do
            let(:rule_list) do
              [{ if: '$VAR == null', needs: [{ name: 'test', artifacts: true, optional: false }] }]
            end

            it {
              is_expected.to eq(described_class::Result.new('on_success', nil, nil, nil, nil, nil))
            }
          end

          context 'when multiple needs are specified' do
            let(:rule_list) do
              [{ if: '$VAR == null',
                 needs: [{ name: 'test', artifacts: true, optional: false },
                   { name: 'rspec', artifacts: true, optional: false }] }]
            end

            it {
              is_expected.to eq(described_class::Result.new('on_success', nil, nil, nil, nil, nil))
            }
          end

          context 'when there are no needs specified' do
            let(:rule_list) { [{ if: '$VAR == null' }] }

            it { is_expected.to eq(described_class::Result.new('on_success', nil, nil, nil, nil, nil)) }
          end

          context 'when need is specified with additional attibutes' do
            let(:rule_list) do
              [{ if: '$VAR == null', needs:  [{
                artifacts: true,
                name: 'test',
                optional: false,
                when: 'never'
              }] }]
            end

            it {
              is_expected.to eq(
                described_class::Result.new('on_success', nil, nil, nil, nil, nil))
            }
          end
        end
      end
    end

    context 'with variables' do
      context 'with matching rule' do
        let(:rule_list) { [{ if: '$VAR == null', variables: { MY_VAR: 'my var' } }] }

        it { is_expected.to eq(described_class::Result.new('on_success', nil, nil, { MY_VAR: 'my var' })) }
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

      it { is_expected.to eq(described_class::Result.new('on_success')) }
    end
  end

  describe 'Gitlab::Ci::Build::Rules::Result' do
    let(:when_value) { 'on_success' }
    let(:start_in) { nil }
    let(:allow_failure) { nil }
    let(:variables) { nil }
    let(:needs) { nil }

    subject(:result) do
      Gitlab::Ci::Build::Rules::Result.new(when_value, start_in, allow_failure, variables, needs)
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

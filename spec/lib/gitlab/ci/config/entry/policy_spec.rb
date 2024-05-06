# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Policy, feature_category: :continuous_integration do
  let(:entry) { described_class.new(config) }

  context 'when using simplified policy' do
    describe 'validations' do
      context 'when entry config value is valid' do
        context 'when config is a branch or tag name' do
          let(:config) { %w[master feature/branch] }

          describe '#valid?' do
            it 'is valid' do
              expect(entry).to be_valid
            end
          end

          describe '#value' do
            it 'returns refs hash' do
              expect(entry.value).to eq(refs: config)
            end
          end
        end

        context 'when config is a regexp' do
          let(:config) { ['/^issue-.*$/'] }

          describe '#valid?' do
            it 'is valid' do
              expect(entry).to be_valid
            end
          end
        end

        context 'when config is an empty regexp' do
          let(:config) { ['//'] }

          describe '#valid?' do
            it 'is valid' do
              expect(entry).to be_valid
            end
          end
        end

        context 'when using unsafe regexp' do
          let(:config) { ['/^(?!master).+/'] }

          it 'is not valid' do
            expect(entry).not_to be_valid
          end
        end

        context 'when config is a special keyword' do
          let(:config) { %w[tags triggers branches] }

          describe '#valid?' do
            it 'is valid' do
              expect(entry).to be_valid
            end
          end
        end
      end

      context 'when entry value is not valid' do
        let(:config) { [1] }

        describe '#errors' do
          it 'saves errors' do
            expect(entry.errors)
              .to include(/policy config should be an array of strings or regular expressions/)
          end
        end
      end
    end
  end

  context 'when using complex policy' do
    context 'when specifying refs policy' do
      let(:config) { { refs: ['master'] } }

      it 'is a correct configuraton' do
        expect(entry).to be_valid
        expect(entry.value).to eq(refs: %w[master])
      end
    end

    context 'when using unsafe regexp' do
      let(:config) { { refs: ['/^(?!master).+/'] } }

      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end

    context 'when specifying kubernetes policy' do
      let(:config) { { kubernetes: 'active' } }

      it 'is a correct configuraton' do
        expect(entry).to be_valid
        expect(entry.value).to eq(kubernetes: 'active')
      end
    end

    context 'when specifying invalid kubernetes policy' do
      let(:config) { { kubernetes: 'something' } }

      it 'reports an error about invalid policy' do
        expect(entry.errors).to include(/unknown value: something/)
      end
    end

    context 'when specifying valid variables expressions policy' do
      let(:config) { { variables: ['$VAR == null'] } }

      it 'is a correct configuraton' do
        expect(entry).to be_valid
        expect(entry.value).to eq(config)
      end
    end

    context 'when specifying variables expressions in invalid format' do
      let(:config) { { variables: '$MY_VAR' } }

      it 'reports an error about invalid format' do
        expect(entry.errors).to include(/should be an array of strings/)
      end
    end

    context 'when specifying invalid variables expressions statement' do
      let(:config) { { variables: ['$MY_VAR =='] } }

      it 'reports an error about invalid statement' do
        expect(entry.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when specifying invalid variables expressions token' do
      let(:config) { { variables: ['$MY_VAR == 123'] } }

      it 'reports an error about invalid expression' do
        expect(entry.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when using invalid variables expressions regexp' do
      let(:config) { { variables: ['$MY_VAR =~ /some ( thing/'] } }

      it 'reports an error about invalid expression' do
        expect(entry.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when specifying a valid changes policy' do
      let(:config) { { changes: %w[some/* paths/**/*.rb] } }

      it 'is a correct configuraton' do
        expect(entry).to be_valid
        expect(entry.value).to eq(config)
      end
    end

    context 'when changes policy is invalid' do
      let(:config) { { changes: 'some/*' } }

      it 'returns errors' do
        expect(entry.errors).to include(/changes should be an array of strings/)
      end
    end

    context 'when changes policy is invalid' do
      let(:config) { { changes: [1, 2] } }

      it 'returns errors' do
        expect(entry.errors).to include(/changes should be an array of strings/)
      end
    end

    context 'when specifying unknown policy' do
      let(:config) { { refs: ['master'], invalid: :something } }

      it 'returns error about invalid key' do
        expect(entry.errors).to include(/unknown keys: invalid/)
      end
    end

    context 'when policy is empty' do
      let(:config) { {} }

      it 'is not a valid configuration' do
        expect(entry.errors).to include(/can't be blank/)
      end
    end
  end

  context 'when policy strategy does not match' do
    let(:config) { 'string strategy' }

    it 'returns information about errors' do
      expect(entry.errors)
        .to include(/has to be either an array of conditions or a hash/)
    end
  end

  describe '#value' do
    context 'when default value has been provided' do
      before do
        entry.default = { refs: %w[branches tags] }
      end

      context 'when user overrides default values' do
        let(:config) { { refs: %w[feature], variables: %w[$VARIABLE] } }

        it 'does not include default values' do
          expect(entry.value).to eq config
        end
      end

      context 'when default value has not been defined' do
        let(:config) { { variables: %w[$VARIABLE] } }

        it 'includes default values' do
          expect(entry.value).to eq(refs: %w[branches tags], variables: %w[$VARIABLE])
        end
      end
    end
  end

  describe '.default' do
    it 'does not have default policy' do
      expect(described_class.default).to be_nil
    end
  end
end

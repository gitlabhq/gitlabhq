# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIde::Config::Entry::Global, feature_category: :web_ide do
  let(:global) { described_class.new(hash) }

  describe '.nodes' do
    it 'returns a hash' do
      expect(described_class.nodes).to be_a(Hash)
    end

    context 'when filtering all the entry/node names' do
      it 'contains the expected node names' do
        expect(described_class.nodes.keys).to match_array(described_class.allowed_keys)
      end
    end
  end

  context 'when configuration is valid' do
    context 'when some entries defined' do
      let(:hash) do
        { terminal: { before_script: ['ls'], variables: {}, script: 'sleep 10s', services: ['mysql'] } }
      end

      describe '#compose!' do
        before do
          global.compose!
        end

        it 'creates nodes hash' do
          expect(global.descendants).to be_an Array
        end

        it 'creates node object for each entry' do
          expect(global.descendants.count).to eq described_class.allowed_keys.length
        end

        it 'creates node object using valid class' do
          expect(global.descendants.first)
            .to be_an_instance_of WebIde::Config::Entry::Terminal
        end

        it 'sets correct description for nodes' do
          expect(global.descendants.first.description)
            .to eq 'Configuration of the webide terminal.'
        end

        describe '#leaf?' do
          it 'is not leaf' do
            expect(global).not_to be_leaf
          end
        end
      end

      context 'when not composed' do
        describe '#terminal_value' do
          it 'returns nil' do
            expect(global.terminal_value).to be nil
          end
        end

        describe '#leaf?' do
          it 'is leaf' do
            expect(global).to be_leaf
          end
        end
      end

      context 'when composed' do
        before do
          global.compose!
        end

        describe '#errors' do
          it 'has no errors' do
            expect(global.errors).to be_empty
          end
        end

        describe '#terminal_value' do
          it 'returns correct script' do
            expect(global.terminal_value).to eq({
              tag_list: [],
              job_variables: [],
              options: {
                before_script: ['ls'],
                script: ['sleep 10s'],
                services: [{ name: "mysql" }]
              }
            })
          end
        end
      end
    end
  end

  context 'when configuration is not valid' do
    before do
      global.compose!
    end

    context 'when job does not have valid before script' do
      let(:hash) do
        { terminal: { before_script: 100 } }
      end

      describe '#errors' do
        it 'reports errors about missing script' do
          expect(global.errors)
            .to include(
              "terminal:before_script config should be a string or a nested array of strings up to 10 levels deep"
            )
        end
      end
    end
  end

  context 'when value is not a hash' do
    let(:hash) { [] }

    describe '#valid?' do
      it 'is not valid' do
        expect(global).not_to be_valid
      end
    end

    describe '#errors' do
      it 'returns error about invalid type' do
        expect(global.errors.first).to match(/should be a hash/)
      end
    end
  end

  describe '#specified?' do
    it 'is concrete entry that is defined' do
      expect(global.specified?).to be true
    end
  end

  describe '#[]' do
    before do
      global.compose!
    end

    let(:hash) do
      { terminal: { before_script: ['ls'] } }
    end

    context 'when entry exists' do
      it 'returns correct entry' do
        expect(global[:terminal])
          .to be_an_instance_of WebIde::Config::Entry::Terminal
        expect(global[:terminal][:before_script].value).to eq ['ls']
      end
    end

    context 'when entry does not exist' do
      it 'always return unspecified node' do
        expect(global[:some][:unknown][:node])
          .not_to be_specified
      end
    end
  end
end

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/security/to_json'

describe RuboCop::Cop::Security::ToJson do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'ignores calls except `to_json`' do
    inspect_source(cop, 'render json: foo')

    expect(cop.offenses).to be_empty
  end

  context '`to_json` without options' do
    it 'does nothing when sent to nil receiver' do
      inspect_source(cop, 'to_json')

      expect(cop.offenses).to be_empty
    end

    it 'does nothing when sent to a Hash' do
      inspect_source(cop, '{}.to_json')

      expect(cop.offenses).to be_empty
    end

    it 'does nothing when sent to a Serializer instance' do
      inspect_source(cop, 'MergeRequestSerializer.new.represent(issuable).to_json')

      expect(cop.offenses).to be_empty
    end

    it 'adds an offense when sent to any other receiver' do
      inspect_source(cop, 'foo.to_json')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to contain_exactly('foo.to_json')
      end
    end
  end

  context '`to_json` with options' do
    it 'does nothing when provided `only`' do
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(only: [:name, :username])
      EOS

      expect(cop.offenses).to be_empty
    end

    it 'does nothing when provided `only` and `methods`' do
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(
          only: [:name, :username],
          methods: [:avatar_url]
        )
      EOS

      expect(cop.offenses).to be_empty
    end

    it 'adds an offense to `include`d attributes without `only` option' do
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(
          include: {
            milestone: {},
            assignee: { methods: :avatar_url },
            author: { only: %i[foo bar] },
          }
        )
      EOS

      aggregate_failures do
        expect(cop.offenses.size).to eq(2)
        expect(cop.highlights).to contain_exactly(
          'milestone: {}',
          'assignee: { methods: :avatar_url }'
        )
      end
    end

    it 'handles a top-level `only` with child `include`s' do
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(
          only: [:foo, :bar],
          include: {
            assignee: { methods: :avatar_url },
            author: { only: %i[foo bar] }
          }
        )
      EOS

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights)
          .to contain_exactly('assignee: { methods: :avatar_url }')
      end
    end

    it 'adds an offense for `include: [...]`' do
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(include: %i[foo bar baz])
      EOS

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to contain_exactly('include: %i[foo bar baz]')
      end
    end

    it 'adds an offense for `except`' do
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(except: [:private_token])
      EOS

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to contain_exactly('except: [:private_token]')
      end
    end
  end
end

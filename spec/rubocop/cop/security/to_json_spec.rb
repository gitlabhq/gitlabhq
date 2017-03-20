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

  context 'to_json with options' do
    it 'does nothing when provided `only`' do
      # s(:hash,
      #   s(:pair,
      #     s(:sym, :only),
      #     s(:array,
      #       s(:sym, :name),
      #       s(:sym, :username))))
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(only: [:name, :username])
      EOS

      expect(cop.offenses).to be_empty
    end

    it 'does nothing when provided `only` and `methods`' do
      # s(:hash,
      #   s(:pair,
      #     s(:sym, :only),
      #     s(:array,
      #       s(:sym, :name),
      #       s(:sym, :username))),
      #   s(:pair,
      #     s(:sym, :methods),
      #     s(:array,
      #       s(:sym, :avatar_url))))
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(only: [:name, :username], methods: [:avatar_url])
      EOS

      expect(cop.offenses).to be_empty
    end

    it 'adds an offense to `include`d attributes without `only` option' do
      # s(:hash,
      #   s(:pair,
      #     s(:sym, :include),
      #     s(:hash,
      #       s(:pair,
      #         s(:sym, :milestone),
      #         s(:hash)),
      #       s(:pair,
      #         s(:sym, :assignee),
      #         s(:hash,
      #           s(:pair,
      #             s(:sym, :methods),
      #             s(:sym, :avatar_url)))),
      #       s(:pair,
      #         s(:sym, :author),
      #         s(:hash,
      #           s(:pair,
      #             s(:sym, :only),
      #             s(:array,
      #               s(:str, "foo"),
      #               s(:str, "bar"))))))))
      inspect_source(cop, <<~EOS)
        render json: @issue.to_json(
          include: {
            milestone: {},
            assignee: { methods: :avatar_url },
            author: { only: %w[foo bar] },
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

  context 'to_json without options' do
    it 'does nothing when called with nil receiver' do
      inspect_source(cop, 'to_json')

      expect(cop.offenses).to be_empty
    end
    it 'does nothing when called directly on a Hash' do
      inspect_source(cop, '{}.to_json')

      expect(cop.offenses).to be_empty
    end

    it 'adds an offense when called on variable' do
      inspect_source(cop, 'foo.to_json')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to contain_exactly('foo.to_json')
      end
    end
  end
end

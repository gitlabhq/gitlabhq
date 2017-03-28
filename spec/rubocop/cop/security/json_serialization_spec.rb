require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/security/json_serialization'

describe RuboCop::Cop::Security::JsonSerialization do
  include CopHelper

  subject(:cop) { described_class.new }

  shared_examples 'an upstanding constable' do |method|
    it "ignores calls except `#{method}`" do
      inspect_source(cop, 'render json: foo')

      expect(cop.offenses).to be_empty
    end

    context "`#{method}` without options" do
      it 'does nothing when sent to nil receiver' do
        inspect_source(cop, method.to_s)

        expect(cop.offenses).to be_empty
      end

      it 'does nothing when sent to a Hash' do
        inspect_source(cop, "{}.#{method}")

        expect(cop.offenses).to be_empty
      end

      it 'does nothing when sent to a Serializer instance' do
        inspect_source(cop, "MergeRequestSerializer.new.represent(issuable).#{method}")

        expect(cop.offenses).to be_empty
      end

      it 'adds an offense when sent to any other receiver' do
        inspect_source(cop, "foo.#{method}")

        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to contain_exactly("foo.#{method}")
        expect(cop.messages.first).to start_with("Don't use `#{method}`")
      end
    end

    context "`#{method}` with options" do
      it 'does nothing when provided `only`' do
        inspect_source(cop, <<~EOS)
          render json: @issue.#{method}(only: [:name, :username])
        EOS

        expect(cop.offenses).to be_empty
      end

      it 'does nothing when provided `only` and `methods`' do
        inspect_source(cop, <<~EOS)
          render json: @issue.#{method}(
            only: [:name, :username],
            methods: [:avatar_url]
          )
        EOS

        expect(cop.offenses).to be_empty
      end

      it 'adds an offense to `include`d attributes without `only` option' do
        inspect_source(cop, <<~EOS)
          render json: @issue.#{method}(
            include: {
              milestone: {},
              assignee: { methods: :avatar_url },
              author: { only: %i[foo bar] },
            }
          )
        EOS

        expect(cop.offenses.size).to eq(2)
        expect(cop.highlights).to contain_exactly(
          'milestone: {}',
          'assignee: { methods: :avatar_url }'
        )
        expect(cop.messages.first).to start_with("Don't use `#{method}`")
      end

      it 'handles a top-level `only` with child `include`s' do
        inspect_source(cop, <<~EOS)
          render json: @issue.#{method}(
            only: [:foo, :bar],
            include: {
              assignee: { methods: :avatar_url },
              author: { only: %i[foo bar] }
            }
          )
        EOS

        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights)
          .to contain_exactly('assignee: { methods: :avatar_url }')
        expect(cop.messages.first).to start_with("Don't use `#{method}`")
      end

      it 'adds an offense for `include: [...]`' do
        inspect_source(cop, <<~EOS)
          render json: @issue.#{method}(include: %i[foo bar baz])
        EOS

        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to contain_exactly('include: %i[foo bar baz]')
        expect(cop.messages.first).to start_with("Don't use `#{method}`")
      end

      it 'adds an offense for `except`' do
        inspect_source(cop, <<~EOS)
          render json: @issue.#{method}(except: [:private_token])
        EOS

        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to contain_exactly('except: [:private_token]')
        expect(cop.messages.first).to start_with("Don't use `#{method}`")
      end
    end
  end

  it_behaves_like 'an upstanding constable', :to_json
  it_behaves_like 'an upstanding constable', :as_json
end

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/security/to_json'

describe RuboCop::Cop::Security::ToJson do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'ignores calls except `to_json`' do
    inspect_source(cop, "render text: 'Hello'")

    expect(cop.offenses).to be_empty
  end

  context 'to_json with `include`' do
    it 'adds an offense' do
      inspect_source(cop, <<~EOS)
        render json: issue.to_json(
          include: {
            milestone: {},
            assignee: { methods: :avatar_url },
            labels: { methods: :text_color }
          },
          methods: [:task_status, :task_status_short]
        )
      EOS

      aggregate_failures do
        expect(cop.offenses.size).to eq(3)
        expect(cop.highlights).to contain_exactly(
          'milestone: {}',
          'assignee: { methods: :avatar_url }',
          'labels: { methods: :text_color }'
        )
      end
    end

  end

  context 'to_json without `include`' do
    it 'does nothing when `only` is specified' do
      source = %q(current_user.created_projects.where(import_type: "gitlab").to_json(only: [:id, :import_status]))
      inspect_source(cop, source)

      expect(cop.offenses).to be_empty
    end

    # it 'adds an offense without `only`' do
    #   source = %q(current_user.created_projects.where(import_type: "gitlab").to_json(except: [:id, :import_status]))
    #   inspect_source(cop, source)
    #
    #   aggregate_failures do
    #     expect(cop.offenses.size).to eq(1)
    #     expect(cop.highlights).to contain_exactly("except: [:id, :import_status]")
    #   end
    # end
  end

  context 'to_json without options' do
    it 'does nothing when called directly on a Hash' do
      inspect_source(cop, "{}.to_json")

      expect(cop.offenses).to be_empty
    end

    it 'adds an offense when called on object' do
      inspect_source(cop, "foo.to_json")

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.highlights).to contain_exactly('foo.to_json')
      end
    end
  end

  # context 'when a class has a body' do
  #   it 'does nothing' do
  #     inspect_source(cop, 'class CustomError < StandardError; def foo; end; end')
  #
  #     expect(cop.offenses).to be_empty
  #   end
  # end
  #
  # context 'when a class has no explicit superclass' do
  #   it 'does nothing' do
  #     inspect_source(cop, 'class CustomError; end')
  #
  #     expect(cop.offenses).to be_empty
  #   end
  # end
  #
  # context 'when a class has a superclass that does not end in Error' do
  #   it 'does nothing' do
  #     inspect_source(cop, 'class CustomError < BasicObject; end')
  #
  #     expect(cop.offenses).to be_empty
  #   end
  # end
  #
  # context 'when a class is empty and inherits from a class ending in Error' do
  #   context 'when the class is on a single line' do
  #     let(:source) do
  #       <<-SOURCE
  #         module Foo
  #           class CustomError < Bar::Baz::BaseError; end
  #         end
  #       SOURCE
  #     end
  #
  #     let(:expected) do
  #       <<-EXPECTED
  #         module Foo
  #           CustomError = Class.new(Bar::Baz::BaseError)
  #         end
  #       EXPECTED
  #     end
  #
  #     it 'registers an offense' do
  #       expected_highlights = source.split("\n")[1].strip
  #
  #       inspect_source(cop, source)
  #
  #       aggregate_failures do
  #         expect(cop.offenses.size).to eq(1)
  #         expect(cop.offenses.map(&:line)).to eq([2])
  #         expect(cop.highlights).to contain_exactly(expected_highlights)
  #       end
  #     end
  #
  #     it 'autocorrects to the right version' do
  #       autocorrected = autocorrect_source(cop, source, 'foo/custom_error.rb')
  #
  #       expect(autocorrected).to eq(expected)
  #     end
  #   end
  #
  #   context 'when the class is on multiple lines' do
  #     let(:source) do
  #       <<-SOURCE
  #         module Foo
  #           class CustomError < Bar::Baz::BaseError
  #           end
  #         end
  #       SOURCE
  #     end
  #
  #     let(:expected) do
  #       <<-EXPECTED
  #         module Foo
  #           CustomError = Class.new(Bar::Baz::BaseError)
  #         end
  #       EXPECTED
  #     end
  #
  #     it 'registers an offense' do
  #       expected_highlights = source.split("\n")[1..2].join("\n").strip
  #
  #       inspect_source(cop, source)
  #
  #       aggregate_failures do
  #         expect(cop.offenses.size).to eq(1)
  #         expect(cop.offenses.map(&:line)).to eq([2])
  #         expect(cop.highlights).to contain_exactly(expected_highlights)
  #       end
  #     end
  #
  #     it 'autocorrects to the right version' do
  #       autocorrected = autocorrect_source(cop, source, 'foo/custom_error.rb')
  #
  #       expect(autocorrected).to eq(expected)
  #     end
  #   end
  # end
end

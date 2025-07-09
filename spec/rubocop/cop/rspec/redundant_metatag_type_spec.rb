# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rspec/redundant_metatag_type'

RSpec.describe RuboCop::Cop::RSpec::RedundantMetatagType, feature_category: :shared do
  shared_examples 'offense' do |filename, code|
    context "for `#{code}` in `#{filename}`" do
      message_template = "Redundant RSpec metatag `type: %{value}` can be removed since it's inferred by spec location."
      type_regexp = /\btype: :\w+\b/
      match = type_regexp.match(code)
      raise "No `type: ` match in #{code}" unless match

      type_start, type_end = match.offset(0)
      space = " " * type_start
      value = code[(type_start + 'type: '.size)..(type_end - 1)]
      msg = format(message_template, value: value)
      caret = "^" * (type_end - type_start)
      corrected = code.sub(/, #{type_regexp}/, '')

      it 'registers an offense and autocorrects without block parameter' do
        expect_offense(<<~RUBY, "/some/absolute/path/#{filename}")
          #{code}
          #{space}#{caret} #{msg}
          end
        RUBY

        expect_correction(<<~RUBY)
          #{corrected}
          end
        RUBY
      end

      it 'registers an offense and autocorrects with block parameter' do
        expect_offense(<<~RUBY, "/some/absolute/path/#{filename}")
          #{code} |param|
          #{space}#{caret} #{msg}
          end
        RUBY

        expect_correction(<<~RUBY)
          #{corrected} |param|
          end
        RUBY
      end
    end
  end

  shared_examples 'no offense' do |filename, code|
    context "for `#{code}` in `#{filename}` without block parameter" do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY, "/some/absolute/path/#{filename}")
          #{code}
          end
        RUBY
      end
    end

    context "for `#{code}` in `#{filename}` with block parameter" do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY, "/some/absolute/path/#{filename}")
          #{code} |param|
          end
        RUBY
      end
    end
  end

  include_examples 'no offense', 'spec/models/foo_spec.rb', 'some_block type: :model do'

  %w[
    RSpec.describe
    context
    it
  ].each do |block|
    include_examples 'offense', 'spec/models/foo_spec.rb', "#{block} Foo, type: :model do"
    include_examples 'offense', 'ee/spec/models/foo_spec.rb', "#{block} Foo, type: :model do"
    include_examples 'offense', 'spec/models/foo_spec.rb', "#{block} Foo, :tag, type: :model do"
    include_examples 'offense', 'spec/models/foo_spec.rb', "#{block} Foo, other: :tag, type: :model do"
    include_examples 'offense', 'spec/models/foo_spec.rb', "#{block} Foo, type: :model, other: :tag do"
    include_examples 'offense', 'spec/models/nested/foo_spec.rb', "#{block} Foo, type: :model do"

    include_examples 'no offense', 'spec/models/foo_spec.rb', "#{block} Foo do"
    include_examples 'no offense', 'spec/models/foo_spec.rb', "#{block} Foo, some: :tag do"
    include_examples 'no offense', 'spec/models/foo_spec.rb', "#{block} Foo, type: :other do"
    include_examples 'no offense', 'spec/models/foo_spec.rb', "#{block} Foo, type: 'model' do"
    include_examples 'no offense', 'spec/migrations/foo_spec.rb', "#{block} Foo, type: :model do"
    include_examples 'no offense', 'no_spec/foo_spec.rb', "#{block} Foo, type: :model do"
  end
end

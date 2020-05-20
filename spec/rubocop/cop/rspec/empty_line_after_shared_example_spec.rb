# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../rubocop/cop/rspec/empty_line_after_shared_example'

describe RuboCop::Cop::RSpec::EmptyLineAfterSharedExample do
  subject(:cop) { described_class.new }

  it 'flags a missing empty line after `it_behaves_like` block' do
    expect_offense(<<-RUBY)
      RSpec.describe Foo do
        it_behaves_like 'does this' do
        end
        ^^^ Add an empty line after `it_behaves_like` block.
        it_behaves_like 'does that' do
        end
      end
    RUBY

    expect_correction(<<-RUBY)
      RSpec.describe Foo do
        it_behaves_like 'does this' do
        end

        it_behaves_like 'does that' do
        end
      end
    RUBY
  end

  it 'ignores one-line shared examples before shared example blocks' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe Foo do
        it_behaves_like 'does this'
        it_behaves_like 'does that' do
        end
      end
    RUBY
  end

  it 'flags a missing empty line after `shared_examples`' do
    expect_offense(<<-RUBY)
      RSpec.context 'foo' do
        shared_examples do
        end
        ^^^ Add an empty line after `shared_examples` block.
        shared_examples 'something gets done' do
        end
      end
    RUBY

    expect_correction(<<-RUBY)
      RSpec.context 'foo' do
        shared_examples do
        end

        shared_examples 'something gets done' do
        end
      end
    RUBY
  end

  it 'ignores consecutive one-liners' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe Foo do
        it_behaves_like 'do this'
        it_behaves_like 'do that'
      end
    RUBY
  end

  it 'flags mixed one-line and multi-line shared examples' do
    expect_offense(<<-RUBY)
      RSpec.context 'foo' do
        it_behaves_like 'do this'
        it_behaves_like 'do that'
        it_behaves_like 'does this' do
        end
        ^^^ Add an empty line after `it_behaves_like` block.
        it_behaves_like 'do this'
        it_behaves_like 'do that'
      end
    RUBY
  end
end

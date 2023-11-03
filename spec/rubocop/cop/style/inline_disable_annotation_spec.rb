# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/style/inline_disable_annotation'

RSpec.describe RuboCop::Cop::Style::InlineDisableAnnotation, feature_category: :shared do
  it 'registers an offense' do
    expect_offense(<<~RUBY)
      # some other comment
      abc = '1'
      ['this', 'that'].each do |word|
        next if something? # rubocop:disable Some/Cop, Another/Cop
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Inline disabling a cop needs to follow [...]
      end
      # rubocop:disable Some/Cop, Another/Cop - Bad comment
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Inline disabling a cop needs to follow [...]
      # rubocop :todo Some/Cop Some other things
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Inline disabling a cop needs to follow [...]
      # rubocop: disable Some/Cop, Another/Cop Some more stuff
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Inline disabling a cop needs to follow [...]
      # rubocop:disable Some/Cop -- Good comment
      if blah && this # some other comment about nothing
        this.match?(/blah/) # rubocop:disable Some/Cop with a bad comment
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Inline disabling a cop needs to follow [...]
      end
    RUBY
  end

  it 'accepts correctly formatted comment' do
    expect_no_offenses(<<~RUBY)
      # some other comment
      abc = '1'
      ['this', 'that'].each do |word|
        next if something? # rubocop:disable Some/Cop, Another/Cop -- Good comment
      end
      # rubocop:disable Some/Cop, Another/Cop -- Good comment
      # rubocop :todo Some/Cop Some other things -- Good comment
      # rubocop: disable Some/Cop, Another/Cop Some more stuff -- Good comment
      # rubocop:disable Some/Cop -- Good comment
      if blah && this # some other comment about nothing
        this.match?(/blah/) # rubocop:disable Some/Cop -- Good comment
      end
    RUBY
  end
end

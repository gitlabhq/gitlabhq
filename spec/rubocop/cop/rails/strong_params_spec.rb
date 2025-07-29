# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rails/strong_params'

RSpec.describe RuboCop::Cop::Rails::StrongParams, :aggregate_failures, feature_category: :shared do
  it 'flags params as a sole argument of a method' do
    expect_offense(<<~RUBY)
      MyService.execute(params)
                        ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY

    expect_no_corrections
  end

  it 'flags params in first, last, and middle arg position' do
    expect_offense(<<~RUBY)
      MyService.execute(params, ignore)
                        ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY

    expect_no_corrections

    expect_offense(<<~RUBY)
      execute(ignore, params)
                      ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY

    expect_no_corrections

    expect_offense(<<~RUBY)
      user.where(foo: bar, bar: params, another: :argument)
                                ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY

    expect_no_corrections
  end

  it 'flags when unsafe methods are called on params' do
    expect_offense(<<~RUBY)
      MyService(params[:a_value])
                ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY
    expect_offense(<<~RUBY)
      MyService.new(foobar).execute(manipulate_things(params.slice(:a_value)[:foo]))
                                                      ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY
    expect_offense(<<~RUBY)
      execute(params[:a_value].to_s)
              ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY
    expect_offense(<<~RUBY)
      if params.has_key?(:foo)
         ^^^^^^ Pass ActionController::StrongParameters [...]
        do_a_thing
      end
    RUBY
    expect_offense(<<~RUBY)
      puts "Here are the params: \#{params}"
                                   ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY
  end

  it 'flags when params has permit! called on it' do
    expect_offense(<<~RUBY)
      params.permit!
      ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY
  end

  it 'does not flag when params has permit called on it' do
    expect_no_offenses(<<~RUBY)
      params.permit(:something)[:something]
    RUBY
    expect_no_offenses(<<~RUBY)
      url_for(params.permit(:something)[:something])
    RUBY
  end

  it 'does not flag when params has require called on it' do
    expect_no_offenses(<<~RUBY)
      my_method(params.require(:something))
    RUBY
    expect_no_offenses(<<~RUBY)
      def user_params
        params.require(:user).permit(:name, :email)
      end
    RUBY
  end

  it 'does not flag when params has required called on it' do
    expect_no_offenses(<<~RUBY)
      my_method(params.required(:something))
    RUBY
  end

  it 'does not flag assignment of params' do
    expect_no_offenses(<<~RUBY)
      params = {a: 'b'}
    RUBY
  end

  it 'does not flag not params' do
    expect_no_offenses(<<~RUBY)
      MyService.execute(strong_params)
    RUBY
  end

  it 'can correct a simple hash access' do
    expect_offense(<<~RUBY)
      MyService(params[:a_value])
                ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY

    expect_correction(<<~RUBY)
      MyService(params.permit(:a_value)[:a_value])
    RUBY

    expect_offense(<<~RUBY)
      puts params[:a_value][:another_value]
           ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY

    expect_correction(<<~RUBY)
      puts params.permit(:a_value)[:a_value][:another_value]
    RUBY

    expect_offense(<<~RUBY)
      convoluted_key = params[a_method(1, :two)]
                       ^^^^^^ Pass ActionController::StrongParameters [...]
    RUBY

    expect_correction(<<~RUBY)
      convoluted_key = params.permit(a_method(1, :two))[a_method(1, :two)]
    RUBY
  end
end

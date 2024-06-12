# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rails/strong_params'

RSpec.describe RuboCop::Cop::Rails::StrongParams, :aggregate_failures, feature_category: :shared do
  it 'flags params as a sole argument of a method' do
    expect_offense(<<~SOURCE)
      MyService.execute(params)
                        ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_no_corrections
  end

  it 'flags params in first, last, and middle arg position' do
    expect_offense(<<~SOURCE)
      MyService.execute(params, ignore)
                        ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_no_corrections

    expect_offense(<<~SOURCE)
      execute(ignore, params)
                      ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_no_corrections

    expect_offense(<<~SOURCE)
      user.where(foo: bar, bar: params, another: :argument)
                                ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_no_corrections
  end

  it 'flags when unsafe methods are called on params' do
    expect_offense(<<~SOURCE)
      MyService(params[:a_value])
                ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_offense(<<~SOURCE)
      MyService.new(foobar).execute(manipulate_things(params.slice(:a_value)[:foo]))
                                                      ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_offense(<<~SOURCE)
      execute(params[:a_value].to_s)
              ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_offense(<<~SOURCE)
      if params.has_key?(:foo)
         ^^^^^^ Pass ActionController::StrongParameters [...]
        do_a_thing
      end
    SOURCE
    expect_offense(<<~SOURCE)
      puts "Here are the params: \#{params}"
                                   ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
  end

  it 'flags when params has permit! called on it' do
    expect_offense(<<~SOURCE)
      params.permit!
      ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
  end

  it 'does not flag when params has permit called on it' do
    expect_no_offenses(<<~SOURCE)
      params.permit(:something)[:something]
    SOURCE
    expect_no_offenses(<<~SOURCE)
      url_for(params.permit(:something)[:something])
    SOURCE
  end

  it 'does not flag when params has require called on it' do
    expect_no_offenses(<<~SOURCE)
      my_method(params.require(:something))
    SOURCE
    expect_no_offenses(<<~SOURCE)
      def user_params
        params.require(:user).permit(:name, :email)
      end
    SOURCE
  end

  it 'does not flag when params has required called on it' do
    expect_no_offenses(<<~SOURCE)
      my_method(params.required(:something))
    SOURCE
  end

  it 'does not flag assignment of params' do
    expect_no_offenses(<<~SOURCE)
      params = {a: 'b'}
    SOURCE
  end

  it 'does not flag not params' do
    expect_no_offenses(<<~SOURCE)
      MyService.execute(strong_params)
    SOURCE
  end

  it 'can correct a simple hash access' do
    expect_offense(<<~SOURCE)
      MyService(params[:a_value])
                ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_correction(<<~SOURCE)
      MyService(params.permit(:a_value)[:a_value])
    SOURCE

    expect_offense(<<~SOURCE)
      puts params[:a_value][:another_value]
           ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_correction(<<~SOURCE)
      puts params.permit(:a_value)[:a_value][:another_value]
    SOURCE

    expect_offense(<<~SOURCE)
      convoluted_key = params[a_method(1, :two)]
                       ^^^^^^ Pass ActionController::StrongParameters [...]
    SOURCE
    expect_correction(<<~SOURCE)
      convoluted_key = params.permit(a_method(1, :two))[a_method(1, :two)]
    SOURCE
  end
end

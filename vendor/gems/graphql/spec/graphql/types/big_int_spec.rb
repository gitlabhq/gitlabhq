# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::BigInt do
  it "encodes big and small integers as strings" do
    big_integer_1 = 99**99
    expected_str_1 = "369729637649726772657187905628805440595668764281741102430259972423552570455277523421410650010128232727940978889548326540119429996769494359451621570193644014418071060667659301384999779999159200499899"
    assert_equal expected_str_1, GraphQL::Types::BigInt.coerce_result(big_integer_1, nil)
    assert_equal big_integer_1, GraphQL::Types::BigInt.coerce_input(expected_str_1, nil)

    big_integer_2 = -(88**88)
    expected_str_2 = "-1301592834942972055182648307417315364538725075960067827915311484722452340966317215805106820959190833309704934346517741237438752456673499160125624414995891111204155079786496"
    assert_equal expected_str_2, GraphQL::Types::BigInt.coerce_result(big_integer_2, nil)
    assert_equal big_integer_2, GraphQL::Types::BigInt.coerce_input(expected_str_2, nil)

    assert_equal "31", GraphQL::Types::BigInt.coerce_result(31, nil)
    assert_equal(-17, GraphQL::Types::BigInt.coerce_input("-17", nil))
  end

  it "returns `nil` for invalid inputs" do
    assert_nil GraphQL::Types::BigInt.coerce_input("xyz", nil)
    assert_nil GraphQL::Types::BigInt.coerce_input("2.2", nil)
  end

  it 'returns `nil` for nil' do
    assert_nil GraphQL::Types::BigInt.coerce_input(nil, nil)
  end

  it 'parses integers with base 10' do
    number_string = "01000"
    assert_equal 1000, GraphQL::Types::BigInt.coerce_input(number_string, nil)
  end
end

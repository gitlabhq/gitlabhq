# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Fingerprint do
  def build_query(str, var)
    GraphQL::Query.new(Dummy::Schema, str, variables: var)
  end

  it "makes stable variable fingerprints" do
    var1a = { "a" => 1, "b" => 2 }
    var1b = { "a" => 1, "b" => 2 }
    # These keys are in a different order -- they'll be hashed differently.
    var2  = { "b" => 2, "a" => 1 }

    str = "{ __typename }"
    expected_fingerprint = "2/QyWM_3g_5wNtikMDP4MK38YOwDc4JHNUisdCuIgpJ3c="
    assert_equal expected_fingerprint, build_query(str, var1a).variables_fingerprint
    assert_equal expected_fingerprint, build_query(str, var1b).variables_fingerprint
    other_expected_fingerprint = "2/P7dUUyJccyp2t4meoglt2hRVGJyJgXI5cyGC9z_loJ8="
    assert_equal other_expected_fingerprint, build_query(str, var2).variables_fingerprint

    # `nil` is treated like {}
    empty_fingerprint = "0/RBNvo1WzZ4oRRq0W9-hknpT7T8If536DEMBg9hyq_4o="
    assert_equal empty_fingerprint, build_query(str, nil).variables_fingerprint
    assert_equal empty_fingerprint, build_query(str, {}).variables_fingerprint
  end

  it "makes stable query fingerprints" do
    str1a = "{ __typename }"
    str1b = "{ __typename }"
    # Different whitespace is a different query
    str2 = "{\n  __typename\n}\n"
    str3 = "query GetTypename { __typename }"
    expected_fingerprint = "anonymous/f1bmfdIas_MNH_i3vtCIk_Cg24ZEmDYYmzYd0eVt20s="
    assert_equal expected_fingerprint, build_query(str1a, {}).operation_fingerprint
    assert_equal expected_fingerprint, build_query(str1b, {}).operation_fingerprint
    other_expected_fingerprint = "anonymous/jY9zZenob6jjMT_K8hMbgB6v6VSd4iNzCJzydRGFizk="
    assert_equal other_expected_fingerprint, build_query(str2, {}).operation_fingerprint
    op_name_expected_fingerprint = "GetTypename/eKSJYYymUg0JV-FrtUF5idy4Ydt1IE4lZoHzxtzWog0="
    assert_equal op_name_expected_fingerprint, build_query(str3, {}).operation_fingerprint
  end

  it "returns a fingerprint when the query string is blank or nil" do
    nil_query = build_query(nil, {})
    blank_query = build_query("", {})

    assert_equal "anonymous/47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU=", blank_query.operation_fingerprint
    assert_equal "anonymous/47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU=", nil_query.operation_fingerprint
  end

  it "makes combined fingerprints" do
    str1a = "{ __typename }"
    str1b = "{ __typename }"
    str1_fingerprint = "f1bmfdIas_MNH_i3vtCIk_Cg24ZEmDYYmzYd0eVt20s="

    str2 = "query getTypename {\n  __typename\n}\n"
    str2_fingerprint = "PZ4sJYI9Dkw_SxWdh_VdxKEuktK_nIoSvev_0QrEHL8="

    var1a = { "a" => 1, "b" => 2 }
    var1b = { "a" => 1, "b" => 2 }
    var1_fingerprint = "QyWM_3g_5wNtikMDP4MK38YOwDc4JHNUisdCuIgpJ3c="

    # These keys are in a different order -- they'll be hashed differently.
    var2  = { "b" => 2, "a" => 1 }
    var2_fingerprint = "P7dUUyJccyp2t4meoglt2hRVGJyJgXI5cyGC9z_loJ8="

    nil_var_fingerprint = "RBNvo1WzZ4oRRq0W9-hknpT7T8If536DEMBg9hyq_4o="

    assert_equal "anonymous/#{str1_fingerprint}/2/#{var1_fingerprint}", build_query(str1a, var1a).fingerprint
    assert_equal "anonymous/#{str1_fingerprint}/2/#{var1_fingerprint}", build_query(str1b, var1b).fingerprint
    assert_equal "getTypename/#{str2_fingerprint}/0/#{nil_var_fingerprint}", build_query(str2, nil).fingerprint
    assert_equal "anonymous/#{str1_fingerprint}/2/#{var2_fingerprint}", build_query(str1a, var2).fingerprint
    assert_equal "getTypename/#{str2_fingerprint}/2/#{var1_fingerprint}", build_query(str2, var1b).fingerprint

    example_query = build_query(str2, var1b)
    assert_equal example_query.fingerprint, "#{example_query.operation_fingerprint}/#{example_query.variables_fingerprint}"
  end
end

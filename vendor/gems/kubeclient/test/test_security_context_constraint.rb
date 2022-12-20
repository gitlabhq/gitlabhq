require_relative 'test_helper'

# kind: 'SecurityContextConstraints' entity tests.
# This is one of the unusual `kind`s that are already plural (https://github.com/kubernetes/kubernetes/issues/8115).
# We force singular in method names like 'create_endpoint',
# but `kind` should remain plural as in kubernetes.
class TestSecurityContextConstraints < MiniTest::Test
  def test_create_security_context_constraint
    stub_request(:get, %r{/apis/security.openshift.io/v1$}).to_return(
      body: open_test_file('security.openshift.io_api_resource_list.json'),
      status: 200
    )

    testing_scc = Kubeclient::Resource.new(
      metadata: {
        name: 'teleportation'
      },
      runAsUser: {
        type: 'MustRunAs'
      },
      seLinuxContext: {
        type: 'MustRunAs'
      }
    )
    req_body = '{"metadata":{"name":"teleportation"},"runAsUser":{"type":"MustRunAs"},' \
      '"seLinuxContext":{"type":"MustRunAs"},' \
      '"kind":"SecurityContextConstraints","apiVersion":"security.openshift.io/v1"}'

    stub_request(:post, 'http://localhost:8080/apis/security.openshift.io/v1/securitycontextconstraints')
      .with(body: req_body)
      .to_return(body: open_test_file('created_security_context_constraint.json'), status: 201)

    client = Kubeclient::Client.new('http://localhost:8080/apis/security.openshift.io', 'v1')
    created_scc = client.create_security_context_constraint(testing_scc)
    assert_equal('SecurityContextConstraints', created_scc.kind)
    assert_equal('security.openshift.io/v1', created_scc.apiVersion)

    client = Kubeclient::Client.new('http://localhost:8080/apis/security.openshift.io', 'v1',
                                    as: :parsed_symbolized)
    created_scc = client.create_security_context_constraint(testing_scc)
    assert_equal('SecurityContextConstraints', created_scc[:kind])
    assert_equal('security.openshift.io/v1', created_scc[:apiVersion])
  end

  def test_get_security_context_constraints
    stub_request(:get, %r{/apis/security.openshift.io/v1$}).to_return(
      body: open_test_file('security.openshift.io_api_resource_list.json'),
      status: 200
    )
    stub_request(:get, %r{/securitycontextconstraints})
      .to_return(body: open_test_file('security_context_constraint_list.json'), status: 200)
    client = Kubeclient::Client.new('http://localhost:8080/apis/security.openshift.io', 'v1')

    collection = client.get_security_context_constraints(as: :parsed_symbolized)
    assert_equal('SecurityContextConstraintsList', collection[:kind])
    assert_equal('security.openshift.io/v1', collection[:apiVersion])

    # Stripping of 'List' in collection.kind RecursiveOpenStruct mode only is historic.
    collection = client.get_security_context_constraints
    assert_equal('SecurityContextConstraints', collection.kind)
  end
end

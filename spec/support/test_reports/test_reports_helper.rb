module TestReportsHelper
  def create_test_case_rspec_success
    Gitlab::Ci::Reports::TestCase.new(
      name: 'Test#sum when a is 1 and b is 3 returns summary',
      classname: 'spec.test_spec',
      file: './spec/test_spec.rb',
      execution_time: 1.11,
      status: Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
  end

  def create_test_case_rspec_failed
    Gitlab::Ci::Reports::TestCase.new(
      name: 'Test#sum when a is 2 and b is 2 returns summary',
      classname: 'spec.test_spec',
      file: './spec/test_spec.rb',
      execution_time: 2.22,
      system_output: sample_rspec_failed_message,
      status: Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
  end

  def create_test_case_rspec_skipped
    Gitlab::Ci::Reports::TestCase.new(
      name: 'Test#sum when a is 3 and b is 3 returns summary',
      classname: 'spec.test_spec',
      file: './spec/test_spec.rb',
      execution_time: 3.33,
      status: Gitlab::Ci::Reports::TestCase::STATUS_SKIPPED)
  end

  def create_test_case_rspec_error
    Gitlab::Ci::Reports::TestCase.new(
      name: 'Test#sum when a is 4 and b is 4 returns summary',
      classname: 'spec.test_spec',
      file: './spec/test_spec.rb',
      execution_time: 4.44,
      status: Gitlab::Ci::Reports::TestCase::STATUS_ERROR)
  end

  def sample_rspec_failed_message
    <<-EOF.strip_heredoc
      Failure/Error: is_expected.to eq(3)

      expected: 3
            got: -1

      (compared using ==)
      ./spec/test_spec.rb:12:in `block (4 levels) in &lt;top (required)&gt;&apos;
    EOF
  end

  def create_test_case_java_success
    Gitlab::Ci::Reports::TestCase.new(
      name: 'addTest',
      classname: 'CalculatorTest',
      execution_time: 5.55,
      status: Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
  end

  def create_test_case_java_failed
    Gitlab::Ci::Reports::TestCase.new(
      name: 'subtractTest',
      classname: 'CalculatorTest',
      execution_time: 6.66,
      system_output: sample_java_failed_message,
      status: Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
  end

  def create_test_case_java_skipped
    Gitlab::Ci::Reports::TestCase.new(
      name: 'multiplyTest',
      classname: 'CalculatorTest',
      execution_time: 7.77,
      status: Gitlab::Ci::Reports::TestCase::STATUS_SKIPPED)
  end

  def create_test_case_java_error
    Gitlab::Ci::Reports::TestCase.new(
      name: 'divideTest',
      classname: 'CalculatorTest',
      execution_time: 8.88,
      status: Gitlab::Ci::Reports::TestCase::STATUS_ERROR)
  end

  def sample_java_failed_message
    <<-EOF.strip_heredoc
      junit.framework.AssertionFailedError: expected:&lt;1&gt; but was:&lt;3&gt;
      at CalculatorTest.subtractExpression(Unknown Source)
      at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
      at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
      at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    EOF
  end
end

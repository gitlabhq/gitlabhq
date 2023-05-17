# frozen_string_literal: true

module TestReportsHelper
  def create_test_case_rspec_success(name = 'test_spec')
    Gitlab::Ci::Reports::TestCase.new(
      suite_name: 'rspec',
      name: 'Test#sum when a is 1 and b is 3 returns summary',
      classname: "spec.#{name}",
      file: './spec/test_spec.rb',
      execution_time: 1.11,
      status: Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
  end

  def create_test_case_rspec_failed(name = 'test_spec', execution_time = 2.22)
    Gitlab::Ci::Reports::TestCase.new(
      suite_name: 'rspec',
      name: 'Test#sum when a is 1 and b is 3 returns summary',
      classname: "spec.#{name}",
      file: './spec/test_spec.rb',
      execution_time: execution_time,
      system_output: sample_rspec_failed_message,
      status: Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
  end

  def create_test_case_rspec_skipped(name = 'test_spec')
    Gitlab::Ci::Reports::TestCase.new(
      suite_name: 'rspec',
      name: 'Test#sum when a is 3 and b is 3 returns summary',
      classname: "spec.#{name}",
      file: './spec/test_spec.rb',
      execution_time: 3.33,
      status: Gitlab::Ci::Reports::TestCase::STATUS_SKIPPED)
  end

  def create_test_case_rspec_error(name = 'test_spec')
    Gitlab::Ci::Reports::TestCase.new(
      suite_name: 'rspec',
      name: 'Test#sum when a is 4 and b is 4 returns summary',
      classname: "spec.#{name}",
      file: './spec/test_spec.rb',
      execution_time: 4.44,
      status: Gitlab::Ci::Reports::TestCase::STATUS_ERROR)
  end

  def sample_rspec_failed_message
    <<-TEST_REPORT_MESSAGE.strip_heredoc
      Failure/Error: is_expected.to eq(3)

      expected: 3
            got: -1

      (compared using ==)
      ./spec/test_spec.rb:12:in `block (4 levels) in &lt;top (required)&gt;&apos;
    TEST_REPORT_MESSAGE
  end

  def create_test_case_java_success(name = 'addTest')
    Gitlab::Ci::Reports::TestCase.new(
      suite_name: 'java',
      name: name,
      classname: 'CalculatorTest',
      execution_time: 5.55,
      status: Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
  end

  def create_test_case_java_failed(name = 'addTest')
    Gitlab::Ci::Reports::TestCase.new(
      suite_name: 'java',
      name: name,
      classname: 'CalculatorTest',
      execution_time: 6.66,
      system_output: sample_java_failed_message,
      status: Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
  end

  def create_test_case_java_skipped(name = 'addTest')
    Gitlab::Ci::Reports::TestCase.new(
      suite_name: 'java',
      name: name,
      classname: 'CalculatorTest',
      execution_time: 7.77,
      status: Gitlab::Ci::Reports::TestCase::STATUS_SKIPPED)
  end

  def create_test_case_java_error(name = 'addTest')
    Gitlab::Ci::Reports::TestCase.new(
      suite_name: 'java',
      name: name,
      classname: 'CalculatorTest',
      execution_time: 8.88,
      status: Gitlab::Ci::Reports::TestCase::STATUS_ERROR)
  end

  def sample_java_failed_message
    <<-TEST_REPORT_MESSAGE.strip_heredoc
      junit.framework.AssertionFailedError: expected:&lt;1&gt; but was:&lt;3&gt;
      at CalculatorTest.subtractExpression(Unknown Source)
      at java.base/jdk.internal.database.NativeMethodAccessorImpl.invoke0(Native Method)
      at java.base/jdk.internal.database.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
      at java.base/jdk.internal.database.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    TEST_REPORT_MESSAGE
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Test::Junit do
  describe '#parse!' do
    subject { described_class.new.parse!(junit, test_report, job: job) }

    let(:project) { build(:project) }
    let(:job) { double(test_suite_name: 'rspec', max_test_cases_per_report: max_test_cases, project: project) }

    let(:test_report) { Gitlab::Ci::Reports::TestReport.new }
    let(:test_suite) { test_report.get_suite(job.test_suite_name) }
    let(:test_cases) { flattened_test_cases(test_suite) }
    let(:max_test_cases) { 0 }
    let(:junit) { '<testsuites></testsuites>' }

    context 'when data is JUnit style XML' do
      context 'when there are no <testcases> in <testsuite>' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuite></testsuite>
          EOF
        end

        it 'ignores the case' do
          expect { subject }.not_to raise_error

          expect(test_cases.count).to eq(0)
        end
      end

      context 'when there are no <testcases> in <testsuites>' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuites><testsuite /></testsuites>
          EOF
        end

        it 'ignores the case' do
          expect { subject }.not_to raise_error

          expect(test_cases.count).to eq(0)
        end
      end

      context 'when there is only one <testsuite> in <testsuites>' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuites>
              <testsuite name='Math'>
                <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
              </testsuite>
            </testsuites>
          EOF
        end

        it 'parses XML and adds a test case to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases[0].suite_name).to eq('Math')
          expect(test_cases[0].classname).to eq('Calculator')
          expect(test_cases[0].name).to eq('sumTest1')
          expect(test_cases[0].execution_time).to eq(0.01)
        end
      end

      context 'when there is <testcase>' do
        let(:junit) do
          <<-EOF.strip_heredoc
              <testsuite name='Math'>
                <testcase classname='Calculator' name='sumTest1' time='0.01'>
                  #{testcase_content}
                </testcase>
              </testsuite>
          EOF
        end

        let(:test_case) { test_cases[0] }

        before do
          expect { subject }.not_to raise_error
        end

        shared_examples_for '<testcase> XML parser' do |status, output|
          it 'parses XML and adds a test case to the suite' do
            aggregate_failures do
              expect(test_case.suite_name).to eq('Math')
              expect(test_case.classname).to eq('Calculator')
              expect(test_case.name).to eq('sumTest1')
              expect(test_case.execution_time).to eq(0.01)
              expect(test_case.status).to eq(status)
              expect(test_case.system_output).to eq(output)
            end
          end
        end

        context 'and has failure' do
          let(:testcase_content) { '<failure>Some failure</failure>' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_FAILED,
            'Some failure'
        end

        context 'and has failure with no message but has system-err' do
          let(:testcase_content) do
            <<-EOF.strip_heredoc
              <failure></failure>
              <system-err>Some failure</system-err>
            EOF
          end

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_FAILED,
            "System Err:\n\nSome failure"
        end

        context 'and has failure with message, system-out and system-err' do
          let(:testcase_content) do
            <<-EOF.strip_heredoc
              <failure>Some failure</failure>
              <system-out>This is the system output</system-out>
              <system-err>This is the system err</system-err>
            EOF
          end

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_FAILED,
            "Some failure\n\nSystem Out:\n\nThis is the system output\n\nSystem Err:\n\nThis is the system err"
        end

        context 'and has error' do
          let(:testcase_content) { '<error>Some error</error>' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_ERROR,
            'Some error'
        end

        context 'and has error with no message but has system-err' do
          let(:testcase_content) do
            <<-EOF.strip_heredoc
              <error></error>
              <system-err>Some error</system-err>
            EOF
          end

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_ERROR,
            "System Err:\n\nSome error"
        end

        context 'and has error with message, system-out and system-err' do
          let(:testcase_content) do
            <<-EOF.strip_heredoc
              <error>Some error</error>
              <system-out>This is the system output</system-out>
              <system-err>This is the system err</system-err>
            EOF
          end

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_ERROR,
            "Some error\n\nSystem Out:\n\nThis is the system output\n\nSystem Err:\n\nThis is the system err"
        end

        context 'and has skipped' do
          let(:testcase_content) { '<skipped/>' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_SKIPPED, nil

          context 'with an empty double-tag' do
            let(:testcase_content) { '<skipped></skipped>' }

            it_behaves_like '<testcase> XML parser',
              ::Gitlab::Ci::Reports::TestCase::STATUS_SKIPPED, nil
          end
        end

        context 'and has an unknown type' do
          let(:testcase_content) { '<foo>Some foo</foo>' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS,
            nil
        end

        context 'and has no content' do
          let(:testcase_content) { '' }

          it_behaves_like '<testcase> XML parser',
            ::Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS,
            nil
        end
      end

      context 'PHPUnit' do
        let(:junit) do
          <<-EOF.strip_heredoc
          <testsuites>
            <testsuite name="Project Test Suite" tests="1" assertions="1" failures="0" errors="0" time="1.376748">
              <testsuite name="XXX\\FrontEnd\\WebBundle\\Tests\\Controller\\LogControllerTest" file="/Users/mcfedr/projects/xxx/server/tests/XXX/FrontEnd/WebBundle/Tests/Controller/LogControllerTest.php" tests="1" assertions="1" failures="0" errors="0" time="1.376748">
                <testcase name="testIndexAction" class="XXX\\FrontEnd\\WebBundle\\Tests\\Controller\\LogControllerTest" file="/Users/mcfedr/projects/xxx/server/tests/XXX/FrontEnd/WebBundle/Tests/Controller/LogControllerTest.php" line="9" assertions="1" time="1.376748"/>
              </testsuite>
            </testsuite>
          </testsuites>
          EOF
        end

        it 'parses XML and adds a test case to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases.count).to eq(1)
          expect(test_cases.first.suite_name).to eq("XXX\\FrontEnd\\WebBundle\\Tests\\Controller\\LogControllerTest")
          expect(test_cases.first.name).to eq("testIndexAction")
        end
      end

      context 'when there are two test cases' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuite name='Math'>
              <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
              <testcase classname='Calculator' name='sumTest2' time='0.02'></testcase>
            </testsuite>
          EOF
        end

        it 'parses XML and adds test cases to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases[0].suite_name).to eq('Math')
          expect(test_cases[0].classname).to eq('Calculator')
          expect(test_cases[0].name).to eq('sumTest1')
          expect(test_cases[0].execution_time).to eq(0.01)
          expect(test_cases[1].suite_name).to eq('Math')
          expect(test_cases[1].classname).to eq('Calculator')
          expect(test_cases[1].name).to eq('sumTest2')
          expect(test_cases[1].execution_time).to eq(0.02)
        end
      end

      context 'when there are two test suites' do
        let(:junit) do
          <<-EOF.strip_heredoc
            <testsuites>
              <testsuite name='Math'>
                <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
                <testcase classname='Calculator' name='sumTest2' time='0.02'></testcase>
              </testsuite>
              <testsuite>
                <testcase classname='Statemachine' name='happy path' time='100'></testcase>
                <testcase classname='Statemachine' name='unhappy path' time='200'></testcase>
              </testsuite>
            </testsuites>
          EOF
        end

        it 'parses XML and adds test cases to a suite' do
          expect { subject }.not_to raise_error

          expect(test_cases).to contain_exactly(
            have_attributes(
              suite_name: 'Math',
              classname: 'Calculator',
              name: 'sumTest1',
              execution_time: 0.01
            ),
            have_attributes(
              suite_name: 'Math',
              classname: 'Calculator',
              name: 'sumTest2',
              execution_time: 0.02
            ),
            have_attributes(
              suite_name: test_suite.name, # Defaults to test suite instance's name
              classname: 'Statemachine',
              name: 'happy path',
              execution_time: 100
            ),
            have_attributes(
              suite_name: test_suite.name, # Defaults to test suite instance's name
              classname: 'Statemachine',
              name: 'unhappy path',
              execution_time: 200
            )
          )
        end
      end

      context 'when number of test cases exceeds the max_test_cases limit' do
        let(:max_test_cases) { 1 }

        shared_examples_for 'rejecting too many test cases' do
          it 'attaches an error to the TestSuite object' do
            expect { subject }.not_to raise_error
            expect(test_suite.suite_error).to eq("JUnit data parsing failed: number of test cases exceeded the limit of #{max_test_cases}")
          end
        end

        context 'and test cases are unique' do
          let(:junit) do
            <<-EOF.strip_heredoc
            <testsuites>
              <testsuite>
                <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
                <testcase classname='Calculator' name='sumTest2' time='0.02'></testcase>
              </testsuite>
              <testsuite>
                <testcase classname='Statemachine' name='happy path' time='100'></testcase>
                <testcase classname='Statemachine' name='unhappy path' time='200'></testcase>
              </testsuite>
            </testsuites>
            EOF
          end

          it_behaves_like 'rejecting too many test cases'
        end

        context 'and test cases are duplicates' do
          let(:junit) do
            <<-EOF.strip_heredoc
            <testsuites>
              <testsuite>
                <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
                <testcase classname='Calculator' name='sumTest2' time='0.02'></testcase>
              </testsuite>
              <testsuite>
                <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
                <testcase classname='Calculator' name='sumTest2' time='0.02'></testcase>
              </testsuite>
            </testsuites>
            EOF
          end

          it_behaves_like 'rejecting too many test cases'
        end
      end
    end

    context 'when data is not JUnit style XML' do
      let(:junit) { { testsuite: 'abc' }.to_json }

      it 'attaches an error to the TestSuite object' do
        expect { subject }.not_to raise_error
        expect(test_cases).to be_empty
      end
    end

    context 'when data is malformed JUnit XML' do
      let(:junit) do
        <<-EOF.strip_heredoc
          <testsuite>
            <testcase classname='Calculator' name='sumTest1' time='0.01'></testcase>
            <testcase classname='Calculator' name='sumTest2' time='0.02'></testcase
          </testsuite>
        EOF
      end

      it 'attaches an error to the TestSuite object' do
        expect { subject }.not_to raise_error
        expect(test_suite.suite_error).to eq("JUnit XML parsing failed: 4:1: FATAL: expected '>'")
      end

      it 'returns 0 tests cases' do
        subject

        expect(test_cases).to be_empty
        expect(test_suite.total_count).to eq(0)
        expect(test_suite.success_count).to eq(0)
        expect(test_suite.error_count).to eq(0)
      end

      it 'returns a failure status' do
        subject

        expect(test_suite.total_status).to eq(Gitlab::Ci::Reports::TestCase::STATUS_ERROR)
      end
    end

    context 'when data is not XML' do
      let(:junit) { double(:random_trash, size: 1) }

      it 'attaches an error to the TestSuite object' do
        expect { subject }.not_to raise_error
        expect(test_suite.suite_error).to eq('JUnit data parsing failed: no implicit conversion of RSpec::Mocks::Double into String')
      end

      it 'returns 0 tests cases' do
        subject

        expect(test_cases).to be_empty
        expect(test_suite.total_count).to eq(0)
        expect(test_suite.success_count).to eq(0)
        expect(test_suite.error_count).to eq(0)
      end

      it 'returns a failure status' do
        subject

        expect(test_suite.total_status).to eq(Gitlab::Ci::Reports::TestCase::STATUS_ERROR)
      end
    end

    context 'when attachment is specified in failed test case' do
      let(:junit) do
        <<~EOF
          <testsuites>
            <testsuite>
              <testcase classname='Calculator' name='sumTest1' time='0.01'>
                <failure>Some failure</failure>
                <system-out>[[ATTACHMENT|some/path.png]]</system-out>
              </testcase>
            </testsuite>
          </testsuites>
        EOF
      end

      it 'assigns correct attributes to the test case' do
        expect { subject }.not_to raise_error

        expect(test_cases[0].has_attachment?).to be_truthy
        expect(test_cases[0].attachment).to eq("some/path.png")

        expect(test_cases[0].job).to eq(job)
      end

      context 'when attachment is way too long' do
        let(:junit) do
          <<~EOF
            <testsuites>
              <testsuite>
                <testcase classname='Calculator' name='sumTest1' time='0.01'>
                  <failure>Some failure</failure>
                  <system-out>#{'[[ATTACHMENT|' * 20000}some/path.png]]</system-out>
                </testcase>
              </testsuite>
            </testsuites>
          EOF
        end

        it 'assigns correct attributes to the test case' do
          expect { subject }.not_to raise_error

          expect(test_cases[0].has_attachment?).to be_truthy
          expect(test_cases[0].attachment).to eq("some/path.png")

          expect(test_cases[0].job).to eq(job)
        end
      end
    end

    context 'when data contains multiple attachments tag' do
      let(:junit) do
        <<~EOF
          <testsuites>
            <testsuite>
              <testcase classname='Calculator' name='sumTest1' time='0.01'>
                <failure>Some failure</failure>
                <system-out>
                  [[ATTACHMENT|some/path.png]]
                  [[ATTACHMENT|some/path.html]]
                </system-out>
              </testcase>
            </testsuite>
          </testsuites>
        EOF
      end

      it 'adds the first match attachment to a test case' do
        expect { subject }.not_to raise_error

        expect(test_cases[0].has_attachment?).to be_truthy
        expect(test_cases[0].attachment).to eq("some/path.png")
      end
    end

    context 'when data does not match attachment tag regex' do
      let(:junit) do
        <<~EOF
          <testsuites>
            <testsuite>
              <testcase classname='Calculator' name='sumTest1' time='0.01'>
                <failure>Some failure</failure>
                <system-out>[[attachment]some/path.png]]</system-out>
              </testcase>
            </testsuite>
          </testsuites>
        EOF
      end

      it 'does not add attachment to a test case' do
        expect { subject }.not_to raise_error

        expect(test_cases[0].has_attachment?).to be_falsy
        expect(test_cases[0].attachment).to be_nil
      end
    end

    context 'when attachment is specified in test case with error' do
      let(:junit) do
        <<~EOF
          <testsuites>
            <testsuite>
              <testcase classname='Calculator' name='sumTest1' time='0.01'>
                <error>Some error</error>
                <system-out>[[ATTACHMENT|some/path.png]]</system-out>
              </testcase>
            </testsuite>
          </testsuites>
        EOF
      end

      it 'assigns correct attributes to the test case' do
        expect { subject }.not_to raise_error

        expect(test_cases[0].has_attachment?).to be_truthy
        expect(test_cases[0].attachment).to eq("some/path.png")

        expect(test_cases[0].job).to eq(job)
      end
    end

    it 'parses XML using XmlConverter' do
      expect(Gitlab::XmlConverter).to receive(:new).with(junit).once.and_call_original

      subject
    end

    context 'when XML is empty string' do
      let(:junit) { '' }

      it 'returns 0 tests cases and has no errors' do
        expect { subject }.not_to raise_error
        expect(test_suite.suite_error).to be_nil

        expect(test_cases).to be_empty
        expect(test_suite.total_count).to eq(0)
        expect(test_suite.success_count).to eq(0)
        expect(test_suite.error_count).to eq(0)
      end
    end

    private

    def flattened_test_cases(test_suite)
      test_suite.test_cases.flat_map do |status, value|
        value.flat_map do |key, test_case|
          test_case
        end
      end
    end
  end
end

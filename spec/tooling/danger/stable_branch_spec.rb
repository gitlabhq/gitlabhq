# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'gitlab/dangerfiles/spec_helper'
require 'rspec-parameterized'
require 'httparty'

require_relative '../../../tooling/danger/stable_branch'

RSpec.describe Tooling::Danger::StableBranch, feature_category: :delivery do
  using RSpec::Parameterized::TableSyntax

  include_context 'with dangerfile'
  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_api) { double('Api') } # rubocop:disable RSpec/VerifiedDoubles
  let(:gitlab_gem_client) { double('gitlab') } # rubocop:disable RSpec/VerifiedDoubles

  let(:stable_branch) { fake_danger.new(helper: fake_helper) }

  describe '#check!' do
    subject { stable_branch.check! }

    shared_examples 'without a failure' do
      it 'does not add a failure' do
        expect(stable_branch).not_to receive(:fail)

        subject
      end
    end

    shared_examples 'with a failure' do |failure_message|
      it 'fails' do
        expect(stable_branch).to receive(:fail).with(failure_message)

        subject
      end
    end

    shared_examples 'with a warning' do |warning_message|
      it 'warns' do
        expect(stable_branch).to receive(:warn).with(warning_message)

        subject
      end
    end

    shared_examples 'bypassing when flaky test or docs only' do
      context 'when failure::flaky-test label is present' do
        let(:flaky_test_label_present) { true }

        it_behaves_like 'without a failure'
      end

      context 'with only docs changes' do
        let(:changes_by_category_response) { { docs: ['foo.md'] } }

        it_behaves_like 'without a failure'
      end
    end

    context 'when not applicable' do
      where(:stable_branch?, :security_mr?) do
        true  | true
        false | true
        false | false
      end

      with_them do
        before do
          allow(fake_helper).to receive(:mr_target_branch).and_return(stable_branch? ? '15-1-stable-ee' : 'main')
          allow(fake_helper).to receive(:security_mr?).and_return(security_mr?)
        end

        it_behaves_like 'without a failure'
      end
    end

    context 'when applicable' do
      let(:target_branch) { '15-1-stable-ee' }
      let(:source_branch) { 'my_bug_branch' }
      let(:feature_label_present) { false }
      let(:bug_label_present) { true }
      let(:pipeline_expedite_label_present) { false }
      let(:flaky_test_label_present) { false }
      let(:response_success) { true }

      let(:changes_by_category_response) do
        {
          graphql: ['bar.rb']
        }
      end

      let(:pipeline_bridges_response) do
        [
          { 'name' => 'e2e:package-and-test',
            'status' => 'success' }
        ]
      end

      let(:parsed_response) do
        [
          { 'version' => '15.1.1' },
          { 'version' => '15.1.0' },
          { 'version' => '15.0.2' },
          { 'version' => '15.0.1' },
          { 'version' => '15.0.0' },
          { 'version' => '14.10.3' },
          { 'version' => '14.10.2' },
          { 'version' => '14.9.3' }
        ]
      end

      let(:version_response) do
        instance_double(
          HTTParty::Response,
          success?: response_success,
          parsed_response: parsed_response
        )
      end

      before do
        allow(fake_helper).to receive(:mr_target_branch).and_return(target_branch)
        allow(fake_helper).to receive(:mr_source_branch).and_return(source_branch)
        allow(fake_helper).to receive(:security_mr?).and_return(false)
        allow(fake_helper).to receive(:mr_target_project_id).and_return(1)
        allow(fake_helper).to receive(:mr_has_labels?).with('type::feature').and_return(feature_label_present)
        allow(fake_helper).to receive(:mr_has_labels?).with('type::bug').and_return(bug_label_present)
        allow(fake_helper).to receive(:mr_has_labels?).with('pipeline:expedite')
          .and_return(pipeline_expedite_label_present)
        allow(fake_helper).to receive(:mr_has_labels?).with('failure::flaky-test')
          .and_return(flaky_test_label_present)
        allow(fake_helper).to receive(:changes_by_category).and_return(changes_by_category_response)
        allow(HTTParty).to receive(:get).with(/page=1/).and_return(version_response)
        allow(fake_helper).to receive(:api).and_return(fake_api)
        allow(stable_branch).to receive(:gitlab).and_return(gitlab_gem_client)
        allow(gitlab_gem_client).to receive(:mr_json).and_return({ 'head_pipeline' => { 'id' => '1' } })
        allow(gitlab_gem_client).to receive(:api).and_return(fake_api)
        allow(fake_api).to receive(:pipeline_bridges).with(1, '1')
          .and_return(pipeline_bridges_response)
      end

      # the stubbed behavior above is the success path
      it_behaves_like 'without a failure'

      context 'with a feature label' do
        let(:feature_label_present) { true }

        it_behaves_like 'with a failure', described_class::FEATURE_ERROR_MESSAGE
      end

      context 'without a bug label' do
        let(:bug_label_present) { false }

        it_behaves_like 'with a failure', described_class::BUG_ERROR_MESSAGE
      end

      context 'with a pipeline:expedite label' do
        let(:pipeline_expedite_label_present) { true }

        it_behaves_like 'with a failure', described_class::PIPELINE_EXPEDITE_ERROR_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when no package-and-test job is found' do
        let(:pipeline_bridges_response) { nil }

        it_behaves_like 'with a failure', described_class::NEEDS_PACKAGE_AND_TEST_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when package-and-test job is in manual state' do
        described_class::FAILING_PACKAGE_AND_TEST_STATUSES.each do |status|
          let(:pipeline_bridges_response) do
            [
              { 'name' => 'e2e:package-and-test',
                'status' => status }
            ]
          end

          it_behaves_like 'with a failure', described_class::NEEDS_PACKAGE_AND_TEST_MESSAGE
          it_behaves_like 'bypassing when flaky test or docs only'
        end
      end

      context 'when package-and-test job is in a non-successful state' do
        let(:pipeline_bridges_response) do
          [
            { 'name' => 'e2e:package-and-test',
              'status' => 'running' }
          ]
        end

        it_behaves_like 'with a warning', described_class::WARN_PACKAGE_AND_TEST_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when no pipeline is found' do
        before do
          allow(gitlab_gem_client).to receive(:mr_json).and_return({})
        end

        it_behaves_like 'with a failure', described_class::NEEDS_PACKAGE_AND_TEST_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when not an applicable version' do
        let(:target_branch) { '14-9-stable-ee' }

        it_behaves_like 'with a warning', described_class::VERSION_WARNING_MESSAGE
      end

      context 'when the version API request fails' do
        let(:response_success) { false }

        it_behaves_like 'with a warning', described_class::FAILED_VERSION_REQUEST_MESSAGE
      end

      context 'when more than one page of versions is needed' do
        # we target a version we know will not be returned in the first request
        let(:target_branch) { '14-10-stable-ee' }

        let(:first_version_response) do
          instance_double(
            HTTParty::Response,
            success?: response_success,
            parsed_response: [
              { 'version' => '15.1.1' },
              { 'version' => '15.1.0' },
              { 'version' => '15.0.2' },
              { 'version' => '15.0.1' }
            ]
          )
        end

        let(:second_version_response) do
          instance_double(
            HTTParty::Response,
            success?: response_success,
            parsed_response: [
              { 'version' => '15.0.0' },
              { 'version' => '14.10.3' },
              { 'version' => '14.10.2' },
              { 'version' => '14.9.3' }
            ]
          )
        end

        before do
          allow(HTTParty).to receive(:get).with(/page=1/).and_return(first_version_response)
          allow(HTTParty).to receive(:get).with(/page=2/).and_return(second_version_response)
        end

        it_behaves_like 'without a failure'
      end

      context 'when too many version API requests are made' do
        let(:parsed_response) { [{ 'version' => '15.0.0' }] }

        it 'adds a warning' do
          expect(HTTParty).to receive(:get).and_return(version_response).at_least(10).times
          expect(stable_branch).to receive(:warn).with(described_class::FAILED_VERSION_REQUEST_MESSAGE)

          subject
        end
      end
    end
  end

  describe '#non_security_stable_branch?' do
    subject { stable_branch.non_security_stable_branch? }

    where(:stable_branch?, :security_mr?, :expected_result) do
      true  | true  | false
      false | true  | false
      true  | false | true
      false | false | false
    end

    with_them do
      before do
        allow(fake_helper).to receive(:mr_target_branch).and_return(stable_branch? ? '15-1-stable-ee' : 'main')
        allow(fake_helper).to receive(:security_mr?).and_return(security_mr?)
      end

      it { is_expected.to eq(expected_result) }
    end
  end
end

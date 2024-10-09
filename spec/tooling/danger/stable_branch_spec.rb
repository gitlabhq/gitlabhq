# frozen_string_literal: true

require 'rspec-parameterized'
require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
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
      let(:current_stable_branch) { '15-1-stable-ee' }

      where(:stable_branch?, :security_mr?) do
        true  | true
        false | true
        false | false
      end

      with_them do
        before do
          allow(fake_helper).to receive(:mr_target_branch).and_return(stable_branch? ? current_stable_branch : 'main')
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
          {
            'name' => 'e2e:test-on-omnibus-ee',
            'status' => pipeline_bridge_state,
            'downstream_pipeline' => {
              'id' => '123',
              'status' => package_and_qa_state
            }
          }
        ]
      end

      let(:pipeline_bridge_state) { 'running' }
      let(:package_and_qa_state) { 'success' }

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

      let(:mr_description_response) do
        %(
        <!--
        Please don't remove this comment...

        template sourced from
        https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Stable%20Branch.md
        -->
        ## What does this MR do and why?
        )
      end

      before do
        allow(fake_helper).to receive(:mr_target_branch).and_return(target_branch)
        allow(fake_helper).to receive(:mr_source_branch).and_return(source_branch)
        allow(fake_helper).to receive(:security_mr?).and_return(false)
        allow(fake_helper).to receive(:mr_target_project_id).and_return(1)
        allow(fake_helper).to receive(:mr_has_labels?).with('type::feature').and_return(feature_label_present)
        allow(fake_helper).to receive(:mr_has_labels?).with('type::bug').and_return(bug_label_present)
        allow(fake_helper).to receive(:mr_has_labels?).with('pipeline::expedited')
          .and_return(pipeline_expedite_label_present)
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
        allow(fake_helper).to receive(:mr_description).and_return(mr_description_response)
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

      context 'with only documentation changes and no bug label' do
        let(:bug_label_present) { false }
        let(:changes_by_category_response) { { docs: ['foo.md'] } }

        it_behaves_like 'without a failure'
      end

      context 'with a pipeline::expedited label' do
        let(:pipeline_expedite_label_present) { true }

        it_behaves_like 'with a failure', described_class::PIPELINE_EXPEDITED_ERROR_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when no test-on-omnibus bridge is found' do
        let(:pipeline_bridges_response) { nil }

        it_behaves_like 'with a failure', described_class::NEEDS_PACKAGE_AND_TEST_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when test-on-omnibus bridge is created' do
        let(:pipeline_bridge_state) { 'created' }

        it_behaves_like 'with a warning', described_class::WARN_PACKAGE_AND_TEST_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when test-on-omnibus bridge has been canceled and no downstream pipeline is generated' do
        let(:pipeline_bridge_state) { 'canceled' }

        let(:pipeline_bridges_response) do
          [
            {
              'name' => 'e2e:test-on-omnibus-ee',
              'status' => pipeline_bridge_state,
              'downstream_pipeline' => nil
            }
          ]
        end

        it_behaves_like 'with a failure', described_class::NEEDS_PACKAGE_AND_TEST_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when test-on-omnibus job is in a non-successful state' do
        let(:package_and_qa_state) { 'running' }

        it_behaves_like 'with a warning', described_class::WARN_PACKAGE_AND_TEST_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when test-on-omnibus job is in manual state' do
        let(:package_and_qa_state) { 'manual' }

        it_behaves_like 'with a failure', described_class::NEEDS_PACKAGE_AND_TEST_MESSAGE
        it_behaves_like 'bypassing when flaky test or docs only'
      end

      context 'when test-on-omnibus job is canceled' do
        let(:package_and_qa_state) { 'canceled' }

        it_behaves_like 'with a failure', described_class::NEEDS_PACKAGE_AND_TEST_MESSAGE
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
        let(:target_branch) { '15-0-stable-ee' }

        it 'warns about the test-on-omnibus pipeline and the version' do
          expect(stable_branch).to receive(:warn).with(described_class::WARN_PACKAGE_AND_TEST_MESSAGE)
          expect(stable_branch).to receive(:warn).with(described_class::VERSION_WARNING_MESSAGE)

          subject
        end
      end

      context 'with multiple test-on-omnibus pipelines' do
        let(:pipeline_bridges_response) do
          [
            {
              'name' => 'e2e:test-on-omnibus-ee',
              'status' => 'success',
              'downstream_pipeline' => {
                'id' => '123',
                'status' => package_and_qa_state
              }
            },
            {
              'name' => 'follow-up:e2e:test-on-omnibus-ee',
              'status' => 'failed',
              'downstream_pipeline' => {
                'id' => '456',
                'status' => 'failed'
              }
            }
          ]
        end

        it_behaves_like 'without a failure'
      end

      context 'when the version API request fails' do
        let(:response_success) { false }

        it 'warns about the test-on-omnibus pipeline and the version request' do
          expect(stable_branch).to receive(:warn).with(described_class::WARN_PACKAGE_AND_TEST_MESSAGE)
          expect(stable_branch).to receive(:warn).with(described_class::FAILED_VERSION_REQUEST_MESSAGE)

          subject
        end
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

      context 'when the MR body does not contain the template source' do
        let(:mr_description_response) { 'some description' }

        it 'fails about missing template source' do
          expect(stable_branch).to receive(:fail).with(described_class::NEEDS_STABLE_BRANCH_TEMPLATE_MESSAGE)

          subject
        end
      end
    end
  end

  describe '#encourage_package_and_qa_execution?' do
    subject { stable_branch.encourage_package_and_qa_execution? }

    where(:stable_branch?, :security_mr?, :documentation?, :flaky?, :result) do
      # security merge requests
      true  | true  | true  | true  | false
      true  | true  | true  | false | false
      true  | true  | false | true  | false
      true  | true  | false | false | false
      # canonical merge requests with doc and flaky changes only
      true  | false | true  | true  | false
      true  | false | true  | false | false
      true  | false | false | true  | false
      # canonical merge requests with app code
      true  | false | false | false | true
    end

    with_them do
      before do
        allow(fake_helper)
          .to receive(:mr_target_branch)
          .and_return(stable_branch? ? '15-1-stable-ee' : 'main')

        allow(fake_helper)
          .to receive(:security_mr?)
          .and_return(security_mr?)

        allow(fake_helper)
          .to receive(:has_only_documentation_changes?)
          .and_return(documentation?)

        changes_by_category =
          if documentation?
            { docs: ['foo.md'] }
          else
            { graphql: ['bar.rb'] }
          end

        allow(fake_helper)
          .to receive(:changes_by_category)
          .and_return(changes_by_category)

        allow(fake_helper)
          .to receive(:mr_has_labels?)
          .and_return(flaky?)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#valid_stable_branch?' do
    it "returns false when on the default branch" do
      allow(fake_helper).to receive(:mr_target_branch).and_return('main')

      expect(stable_branch.valid_stable_branch?).to be(false)
    end

    it "returns true when on a stable branch" do
      allow(fake_helper).to receive(:mr_target_branch).and_return('15-1-stable-ee')
      allow(fake_helper).to receive(:security_mr?).and_return(false)

      expect(stable_branch.valid_stable_branch?).to be(true)
    end

    it "returns false when on a stable branch on a security MR" do
      allow(fake_helper).to receive(:mr_target_branch).and_return('15-1-stable-ee')
      allow(fake_helper).to receive(:security_mr?).and_return(true)

      expect(stable_branch.valid_stable_branch?).to be(false)
    end
  end
end

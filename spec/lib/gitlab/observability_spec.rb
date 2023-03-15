# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability, feature_category: :error_tracking do
  describe '.observability_url' do
    let(:gitlab_url) { 'https://example.com' }

    subject { described_class.observability_url }

    before do
      stub_config_setting(url: gitlab_url)
    end

    it { is_expected.to eq('https://observe.gitlab.com') }

    context 'when on staging.gitlab.com' do
      let(:gitlab_url) { Gitlab::Saas.staging_com_url }

      it { is_expected.to eq('https://observe.staging.gitlab.com') }
    end

    context 'when overriden via ENV' do
      let(:observe_url) { 'https://example.net' }

      before do
        stub_env('OVERRIDE_OBSERVABILITY_URL', observe_url)
      end

      it { is_expected.to eq(observe_url) }
    end
  end

  describe '.build_full_url' do
    let_it_be(:group) { build_stubbed(:group, id: 123) }
    let(:observability_url) { described_class.observability_url }

    it 'returns the full observability url for the given params' do
      url = described_class.build_full_url(group, '/foo?bar=baz', '/')
      expect(url).to eq("https://observe.gitlab.com/-/123/foo?bar=baz")
    end

    it 'handles missing / from observability_path' do
      url = described_class.build_full_url(group, 'foo?bar=baz', '/')
      expect(url).to eq("https://observe.gitlab.com/-/123/foo?bar=baz")
    end

    it 'sanitises observability_path' do
      url = described_class.build_full_url(group, "/test?groupId=<script>alert('attack!')</script>", '/')
      expect(url).to eq("https://observe.gitlab.com/-/123/test?groupId=alert('attack!')")
    end

    context 'when observability_path is missing' do
      it 'builds the url with the fallback_path' do
        url = described_class.build_full_url(group, nil, '/fallback')
        expect(url).to eq("https://observe.gitlab.com/-/123/fallback")
      end

      it 'defaults to / if fallback_path is also missing' do
        url = described_class.build_full_url(group, nil, nil)
        expect(url).to eq("https://observe.gitlab.com/-/123/")
      end
    end
  end

  describe '.embeddable_url' do
    before do
      stub_config_setting(url: "https://www.gitlab.com")
      # Can't use build/build_stubbed as we want the routes to be generated as well
      create(:group, path: 'test-path', id: 123)
    end

    context 'when URL is valid' do
      where(:input, :expected) do
        [
          [
            "https://www.gitlab.com/groups/test-path/-/observability/explore?observability_path=%2Fexplore%3FgroupId%3D14485840%26left%3D%255B%2522now-1h%2522,%2522now%2522,%2522new-sentry.gitlab.net%2522,%257B%257D%255D",
            "https://observe.gitlab.com/-/123/explore?groupId=14485840&left=%5B%22now-1h%22,%22now%22,%22new-sentry.gitlab.net%22,%7B%7D%5D"
          ],
          [
            "https://www.gitlab.com/groups/test-path/-/observability/explore?observability_path=/goto/foo",
            "https://observe.gitlab.com/-/123/goto/foo"
          ]
        ]
      end

      with_them do
        it 'returns an embeddable observability url' do
          expect(described_class.embeddable_url(input)).to eq(expected)
        end
      end
    end

    context 'when URL is invalid' do
      where(:input) do
        [
          # direct links to observe.gitlab.com
          "https://observe.gitlab.com/-/123/explore",
          'https://observe.gitlab.com/v1/auth/start',

          # invalid GitLab URL
          "not a link",
          "https://foo.bar/groups/test-path/-/observability/explore?observability_path=/explore",
          "http://www.gitlab.com/groups/test-path/-/observability/explore?observability_path=/explore",
          "https://www.gitlab.com:123/groups/test-path/-/observability/explore?observability_path=/explore",
          "https://www.gitlab.com@example.com/groups/test-path/-/observability/explore?observability_path=/explore",
          "https://www.gitlab.com/groups/test-path/-/observability/explore?observability_path=@example.com",

          # invalid group/controller/actions
          "https://www.gitlab.com/groups/INVALID_GROUP/-/observability/explore?observability_path=/explore",
          "https://www.gitlab.com/groups/test-path/-/INVALID_CONTROLLER/explore?observability_path=/explore",
          "https://www.gitlab.com/groups/test-path/-/observability/INVALID_ACTION?observability_path=/explore",

          # invalid observablity path
          "https://www.gitlab.com/groups/test-path/-/observability/explore",
          "https://www.gitlab.com/groups/test-path/-/observability/explore?missing_observability_path=/explore",
          "https://www.gitlab.com/groups/test-path/-/observability/explore?observability_path=/not_embeddable",
          "https://www.gitlab.com/groups/test-path/-/observability/explore?observability_path=/datasources",
          "https://www.gitlab.com/groups/test-path/-/observability/explore?observability_path=not a valid path"
        ]
      end

      with_them do
        it 'returns nil' do
          expect(described_class.embeddable_url(input)).to be_nil
        end
      end

      it 'returns nil if the path detection throws an error' do
        test_url = "https://www.gitlab.com/groups/test-path/-/observability/explore"
        allow(Rails.application.routes).to receive(:recognize_path).with(test_url) {
                                             raise ActionController::RoutingError, 'test'
                                           }
        expect(described_class.embeddable_url(test_url)).to be_nil
      end

      it 'returns nil if parsing observaboility path throws an error' do
        observability_path = 'some-path'
        test_url = "https://www.gitlab.com/groups/test-path/-/observability/explore?observability_path=#{observability_path}"

        allow(URI).to receive(:parse).and_call_original
        allow(URI).to receive(:parse).with(observability_path) {
                        raise URI::InvalidURIError, 'test'
                      }

        expect(described_class.embeddable_url(test_url)).to be_nil
      end
    end
  end

  describe '.allowed_for_action?' do
    let(:group) { build_stubbed(:group) }
    let(:user) { build_stubbed(:user) }

    before do
      allow(described_class).to receive(:allowed?).and_call_original
    end

    it 'returns false if action is nil' do
      expect(described_class.allowed_for_action?(user, group, nil)).to eq(false)
    end

    describe 'allowed? calls' do
      using RSpec::Parameterized::TableSyntax

      where(:action, :permission) do
        :foo          | :admin_observability
        :explore      | :read_observability
        :datasources  | :admin_observability
        :manage       | :admin_observability
        :dashboards   | :read_observability
      end

      with_them do
        it "calls allowed? with #{params[:permission]} when actions is #{params[:action]}" do
          described_class.allowed_for_action?(user, group, action)
          expect(described_class).to have_received(:allowed?).with(user, group, permission)
        end
      end
    end
  end

  describe '.allowed?' do
    let(:user) { build_stubbed(:user) }
    let(:group) { build_stubbed(:group) }
    let(:test_permission) { :read_observability }

    before do
      allow(Ability).to receive(:allowed?).and_return(false)
    end

    subject do
      described_class.allowed?(user, group, test_permission)
    end

    it 'checks if ability is allowed for the given user and group' do
      allow(Ability).to receive(:allowed?).and_return(true)

      subject

      expect(Ability).to have_received(:allowed?).with(user, test_permission, group)
    end

    it 'checks for admin_observability if permission is missing' do
      described_class.allowed?(user, group)

      expect(Ability).to have_received(:allowed?).with(user, :admin_observability, group)
    end

    it 'returns true if the ability is allowed' do
      allow(Ability).to receive(:allowed?).and_return(true)

      expect(subject).to eq(true)
    end

    it 'returns false if the ability is not allowed' do
      allow(Ability).to receive(:allowed?).and_return(false)

      expect(subject).to eq(false)
    end

    it 'returns false if observability url is missing' do
      allow(described_class).to receive(:observability_url).and_return("")

      expect(subject).to eq(false)
    end

    it 'returns false if group is missing' do
      expect(described_class.allowed?(user, nil, :read_observability)).to eq(false)
    end

    it 'returns false if user is missing' do
      expect(described_class.allowed?(nil, group, :read_observability)).to eq(false)
    end
  end
end

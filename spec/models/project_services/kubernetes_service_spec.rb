# frozen_string_literal: true

require 'spec_helper'

describe KubernetesService, :use_clean_rails_memory_store_caching do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:kubernetes_project) }
  let(:service) { create(:kubernetes_service, project: project) }

  describe 'Associations' do
    it { is_expected.to belong_to :project }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
        subject.skip_deprecation_validation = true
      end

      it { is_expected.not_to validate_presence_of(:namespace) }
      it { is_expected.to validate_presence_of(:api_url) }
      it { is_expected.to validate_presence_of(:token) }

      context 'namespace format' do
        before do
          subject.project = project
          subject.api_url = "http://example.com"
          subject.token = "test"
        end

        {
          'foo'  => true,
          '1foo' => true,
          'foo1' => true,
          'foo-bar' => true,
          '-foo' => false,
          'foo-' => false,
          'a' * 63 => true,
          'a' * 64 => false,
          'a.b' => false,
          'a*b' => false,
          'FOO' => true
        }.each do |namespace, validity|
          it "validates #{namespace} as #{validity ? 'valid' : 'invalid'}" do
            subject.namespace = namespace

            expect(subject.valid?).to eq(validity)
          end
        end
      end
    end

    context 'when service is inactive' do
      before do
        subject.project = project
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:api_url) }
      it { is_expected.not_to validate_presence_of(:token) }
    end

    context 'with a deprecated service' do
      let(:kubernetes_service) { create(:kubernetes_service) }

      before do
        kubernetes_service.update_attribute(:active, false)
        kubernetes_service.skip_deprecation_validation = false
        kubernetes_service.properties['namespace'] = "foo"
      end

      it 'does not update attributes' do
        expect(kubernetes_service.save).to be_falsy
      end

      it 'includes an error with a deprecation message' do
        kubernetes_service.valid?
        expect(kubernetes_service.errors[:base].first).to match(/Kubernetes service integration has been disabled/)
      end
    end

    context 'with an active and deprecated service' do
      let(:kubernetes_service) { create(:kubernetes_service) }

      before do
        kubernetes_service.skip_deprecation_validation = false
        kubernetes_service.active = false
        kubernetes_service.properties['namespace'] = 'foo'
        kubernetes_service.save
      end

      it 'deactivates the service' do
        expect(kubernetes_service.active?).to be_falsy
      end

      it 'does not include a deprecation message as error' do
        expect(kubernetes_service.errors.messages.count).to eq(0)
      end

      it 'updates attributes' do
        expect(kubernetes_service.properties['namespace']).to eq("foo")
      end
    end
  end

  describe '#initialize_properties' do
    context 'without a project' do
      it 'leaves the namespace unset' do
        expect(described_class.new.namespace).to be_nil
      end
    end
  end

  describe '#fields' do
    let(:kube_namespace) do
      subject.fields.find { |h| h[:name] == 'namespace' }
    end

    context 'as template' do
      before do
        subject.template = true
      end

      it 'sets the namespace to the default' do
        expect(kube_namespace).not_to be_nil
        expect(kube_namespace[:placeholder]).to eq(subject.class::TEMPLATE_PLACEHOLDER)
      end
    end

    context 'with associated project' do
      before do
        subject.project = project
      end

      it 'sets the namespace to the default' do
        expect(kube_namespace).not_to be_nil
        expect(kube_namespace[:placeholder]).to match(/\A#{Gitlab::PathRegex::PATH_REGEX_STR}-\d+\z/)
      end
    end
  end

  describe "#deprecated?" do
    let(:kubernetes_service) { create(:kubernetes_service) }

    it 'returns true' do
      expect(kubernetes_service.deprecated?).to be_truthy
    end
  end

  describe "#deprecation_message" do
    let(:kubernetes_service) { create(:kubernetes_service) }

    it 'indicates the service is deprecated' do
      expect(kubernetes_service.deprecation_message).to match(/Kubernetes service integration has been disabled/)
    end

    context 'if the service is not active' do
      it 'returns a message' do
        kubernetes_service.update_attribute(:active, false)
        expect(kubernetes_service.deprecation_message).to match(/Fields on this page are not used by GitLab/)
      end
    end
  end
end

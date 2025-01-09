# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Assembla do
  include StubRequests

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { described_class.new }
  end

  describe 'Validations' do
    context 'when active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :token }
    end

    context 'when inactive' do
      it { is_expected.not_to validate_presence_of :token }
    end
  end

  describe "#execute" do
    let_it_be(:user)    { build(:user) }
    let_it_be(:project) { create(:project, :repository) }

    let(:assembla_integration) { described_class.new }
    let(:sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
    let(:api_url) { 'https://atlas.assembla.com/spaces/project_name/github_tool?secret_key=verySecret' }

    it "calls Assembla API" do
      allow(assembla_integration).to receive_messages(
        project_id: project.id,
        project: project,
        token: 'verySecret',
        subdomain: 'project_name'
      )

      stub_full_request(api_url, method: :post).with(body: { payload: sample_data })

      assembla_integration.execute(sample_data)

      expect(WebMock).to have_requested(:post, stubbed_hostname(api_url)).with(
        body: /#{sample_data[:before]}.*#{sample_data[:after]}.*#{project.path}/
      ).once
    end
  end
end

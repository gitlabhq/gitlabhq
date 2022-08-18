require 'spec_helper'

describe OmniAuth::Strategies::CAS3::LogoutRequest do
  let(:strategy) { double('strategy') }
  let(:env) do
    { 'rack.input' => StringIO.new('','r') }
  end
  let(:request) { double('request', params:params, env:env) }
  let(:params) { { 'url' => url, 'logoutRequest' => logoutRequest } }
  let(:url) { 'http://notes.dev/signed_in' }
  let(:logoutRequest) do
    %Q[
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion\" ID="123abc-1234-ab12-cd34-1234abcd" Version="2.0" IssueInstant="#{Time.now.to_s}">
        <saml:NameID>@NOT_USED@</saml:NameID>
        <samlp:SessionIndex>ST-123456-123abc456def</samlp:SessionIndex>
      </samlp:LogoutRequest>
    ]
  end

  subject { described_class.new(strategy, request).call(options) }

  describe 'SAML attributes' do
    let(:callback) { Proc.new{} }
    let(:options) do
      { on_single_sign_out: callback }
    end

    before do
      @rack_input = nil
      allow(callback).to receive(:call) do |req|
        @rack_input = req.env['rack.input'].read
        true
      end
    end

    it 'are parsed and injected into the Rack Request parameters', :skip => true do
      subject
      expect(@rack_input).to eq 'name_id=%40NOT_USED%40&session_index=ST-123456-123abc456def'
    end

    it 'are parsed and injected even if saml defined inside NameID', :skip => true do
      request.params['logoutRequest'] =
        %Q[
          <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="foobarbaz" Version="2.0" IssueInstant="2014-10-19T17:13:50Z">
            <saml:NameID xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">@NOT_USED@</saml:NameID>
            <samlp:SessionIndex>ST-foo-bar</samlp:SessionIndex>
          </samlp:LogoutRequest>
      ]
      subject
      expect(@rack_input).to eq 'name_id=%40NOT_USED%40&session_index=ST-foo-bar'
    end

    it 'are parsed and injected even if saml and samlp namespaces not defined', :skip => true do
      request.params['logoutRequest'] =
        %Q[
          <samlp:LogoutRequest ID="123abc-1234-ab12-cd34-1234abcd" Version="2.0" IssueInstant="#{Time.now.to_s}">
            <saml:NameID>@NOT_USED@</saml:NameID>
            <samlp:SessionIndex>ST-789000-456def789ghi</samlp:SessionIndex>
          </samlp:LogoutRequest>
        ]
      subject
      expect(@rack_input).to eq 'name_id=%40NOT_USED%40&session_index=ST-789000-456def789ghi'
    end

    context 'that raise when parsed' do
      let(:env) { { 'rack.input' => nil } }

      before do
        allow(strategy).to receive(:fail!)
        subject
        expect(strategy).to have_received(:fail!)
      end

      it 'responds with an error', skip: true do
        expect(strategy).to have_received(:fail!)
      end
    end
  end

  describe 'with a configured callback' do
    let(:options) do
      { on_single_sign_out: callback }
    end

    context 'that returns TRUE' do
      let(:callback) { Proc.new{true} }

      it 'responds with OK', skip: true do
        expect(subject[0]).to eq 200
        expect(subject[2].body).to eq ['OK']
      end
    end

    context 'that returns Nil' do
      let(:callback) { Proc.new{} }

      it 'responds with OK', skip: true do
        expect(subject[0]).to eq 200
        expect(subject[2].body).to eq ['OK']
      end
    end

    context 'that returns a tuple' do
      let(:callback) { Proc.new{ [400,{},'Bad Request'] } }

      it 'responds with OK', skip: true do
        expect(subject[0]).to eq 400
        expect(subject[2].body).to eq ['Bad Request']
      end
    end

    context 'that raises an error' do
      let(:exception) { RuntimeError.new('error' )}
      let(:callback) { Proc.new{raise exception} }

      before do
        allow(strategy).to receive(:fail!)
        subject
      end

      it 'responds with an error', skip: true do
        expect(strategy).to have_received(:fail!)
          .with(:logout_request, exception)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Telegram do
  it_behaves_like Integrations::HasAvatar
  it_behaves_like "chat integration", "Telegram" do
    let(:payload) do
      {
        text: be_present
      }
    end
  end

  describe 'validations' do
    subject(:integration) { build(:telegram_integration) }

    context 'when integration is active' do
      before do
        integration.activate!
      end

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:room) }
      it { is_expected.to validate_numericality_of(:thread).only_integer }
    end

    context 'when integration is inactive' do
      before do
        integration.deactivate!
      end

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:room) }
      it { is_expected.not_to validate_numericality_of(:thread).only_integer }
    end
  end

  describe 'before_validation :set_webhook' do
    context 'when token is not present' do
      subject(:integration) { build(:telegram_integration, token: nil) }

      it 'does not set webhook value' do
        expect(integration.webhook).to be_nil
        expect(integration).not_to be_valid
      end
    end

    context 'when token is present' do
      subject(:integration) { build_stubbed(:telegram_integration) }

      it 'sets webhook value' do
        expect(integration).to be_valid
        expect(integration.webhook).to eq("https://api.telegram.org/bot123456:ABC-DEF1234/sendMessage")
      end

      context 'with custom hostname' do
        where(:hostname) do
          ['https://gitlab.example.com', 'https://gitlab.example.com/']
        end

        with_them do
          before do
            integration.hostname = hostname
          end

          it 'sets webhook value with custom hostname' do
            expect(integration).to be_valid
            expect(integration.webhook).to eq("https://gitlab.example.com/bot123456:ABC-DEF1234/sendMessage")
          end
        end
      end
    end
  end

  describe '#custom_data' do
    subject(:custom_data) { integration.send(:custom_data, data) }

    let(:integration) { build(:telegram_integration) }
    let(:data) { {} }

    it 'selects HTML formatting' do
      expect(custom_data).to include(html: true)
    end
  end

  describe '#html_to_plaintext' do
    using RSpec::Parameterized::TableSyntax

    subject(:plaintext) { integration.send(:html_to_plaintext, text) }

    let(:integration) { build(:telegram_integration) }

    where(:text, :expected) do
      '<b>Fix &lt;toolbar&gt; &amp; settings</b>' | 'Fix <toolbar> & settings'
      '<a href="https://gitlab.example.com/?a=1&amp;b=2">Project &amp; tools</a>' |
        'Project & tools (https://gitlab.example.com/?a=1&b=2)'
      '<a href="https://gitlab.example.com/project"><b>Project</b></a>' |
        'Project (https://gitlab.example.com/project)'
      '<a href="https://gitlab.example.com/one">One &amp; tools</a> and ' \
        '<a href="https://gitlab.example.com/two?a=1&amp;b=2"><b>Two</b></a>' |
        'One & tools (https://gitlab.example.com/one) and Two (https://gitlab.example.com/two?a=1&b=2)'
      '&lt;b&gt;literal&lt;/b&gt; &amp;lt;tag&amp;gt;' | '<b>literal</b> &lt;tag&gt;'
      '<b>&quot;Title&quot; &#39;name&#39; &#128640;</b>' | '"Title" \'name\' 🚀'
      "<a href=\"https://gitlab.example.com/project\">First\nsecond</a>" |
        "First\nsecond (https://gitlab.example.com/project)"
      '' | ''
    end

    with_them do
      it 'keeps literal text and link destinations without HTML formatting' do
        expect(plaintext).to eq(expected)
      end
    end
  end

  describe '#notify' do
    let(:text) do
      '<b>Test &amp; &lt;message&gt;</b> <a href="https://gitlab.example.com/project?a=1&amp;b=2">Project</a> ' \
        '<a href="https://gitlab.example.com/other"><b>Other &amp; tools</b></a>'
    end

    let(:message) { instance_double(Integrations::ChatMessage::PushMessage, summary: text) }
    let(:header) { { 'Content-Type' => 'application/json' } }
    let(:response) { instance_double(HTTParty::Response, bad_request?: true, success?: true) }
    let(:body_1) do
      {
        text: text,
        chat_id: integration.room,
        message_thread_id: integration.thread,
        parse_mode: 'HTML'
      }.compact_blank
    end

    let(:body_2) do
      body_1.without(:parse_mode).merge(
        text: 'Test & <message> Project (https://gitlab.example.com/project?a=1&b=2) ' \
          'Other & tools (https://gitlab.example.com/other)'
      )
    end

    subject(:integration) { build(:telegram_integration) }

    before do
      allow(Gitlab::HTTP).to receive(:post).and_return(response)
    end

    it 'removes the parse mode if the first request fails with a bad request' do
      expect(Gitlab::HTTP).to receive(:post).with(integration.webhook,
        { headers: header, body: Gitlab::Json.dump(body_1), max_bytes: an_instance_of(Integer) })
      expect(Gitlab::HTTP).to receive(:post).with(integration.webhook,
        { headers: header, body: Gitlab::Json.dump(body_2), max_bytes: an_instance_of(Integer) })

      integration.send(:notify, message, {})
    end

    it 'makes a second request if the first one fails with a bad request' do
      expect(Gitlab::HTTP).to receive(:post).twice

      integration.send(:notify, message, {})
    end

    context 'when the formatted request succeeds' do
      let(:response) { instance_double(HTTParty::Response, bad_request?: false, success?: true) }

      it 'sends only one request with HTML formatting' do
        expect(Gitlab::HTTP).to receive(:post).once.with(integration.webhook,
          { headers: header, body: Gitlab::Json.dump(body_1), max_bytes: an_instance_of(Integer) })

        expect(integration.send(:notify, message, {})).to eq(response)
      end
    end
  end
end

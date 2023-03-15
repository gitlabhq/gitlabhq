# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spam::AkismetService, feature_category: :instance_resiliency do
  let(:fake_akismet_client) { double(:akismet_client) }
  let(:ip) { '1.2.3.4' }
  let(:user_agent) { 'some user_agent' }
  let(:referer) { 'some referer' }

  let_it_be(:text) { "Would you like to buy some tinned meat product?" }
  let_it_be(:spam_owner) { create(:user) }

  subject do
    options = { ip_address: ip, user_agent: user_agent, referer: referer }
    described_class.new(spam_owner.name, spam_owner.email, text, options)
  end

  before do
    stub_application_setting(akismet_enabled: true)
    allow(subject).to receive(:akismet_client).and_return(fake_akismet_client)
  end

  shared_examples 'no activity if Akismet is not enabled' do |method_call|
    before do
      stub_application_setting(akismet_enabled: false)
    end

    it 'is automatically false' do
      expect(subject.send(method_call)).to be_falsey
    end

    it 'performs no check' do
      expect(fake_akismet_client).not_to receive(:public_send)

      subject.send(method_call)
    end
  end

  shared_examples 'false if Akismet is not available' do |method_call|
    context 'if Akismet is not available' do
      before do
        allow(fake_akismet_client).to receive(:public_send).and_raise(StandardError.new("oh noes!"))
      end

      specify do
        expect(subject.send(method_call)).to be_falsey
      end

      it 'logs an error' do
        expect(Gitlab::AppLogger).to receive(:error).with(/skipping/)

        subject.send(method_call)
      end
    end
  end

  describe '#spam?' do
    it_behaves_like 'no activity if Akismet is not enabled', :spam?, :check

    context 'if Akismet is enabled' do
      it 'correctly transforms options for the akismet client, including spelling of referrer key' do
        expected_check_params = {
          type: 'comment',
          text: text,
          created_at: anything,
          author: spam_owner.name,
          author_email: spam_owner.email,
          # NOTE: The akismet_client needs the option to be named `:referrer`, not `:referer`
          referrer: referer
        }

        expect(fake_akismet_client).to receive(:check).with(ip, user_agent, expected_check_params)
        subject.spam?
      end

      context 'the text is spam' do
        before do
          allow(fake_akismet_client).to receive(:check).and_return([true, false])
        end

        specify do
          expect(subject.spam?).to be_truthy
        end
      end

      context 'the text is blatant spam' do
        before do
          allow(fake_akismet_client).to receive(:check).and_return([false, true])
        end

        specify do
          expect(subject.spam?).to be_truthy
        end
      end

      context 'the text is not spam' do
        before do
          allow(fake_akismet_client).to receive(:check).and_return([false, false])
        end

        specify do
          expect(subject.spam?).to be_falsey
        end
      end

      describe 'error handling' do
        before do
          allow(fake_akismet_client).to receive(:check).and_raise(error)
        end

        context 'StandardError other than ArgumentError is raised' do
          let(:error) { Akismet::Error.new("Lovely spam! Wonderful spam!") }

          specify do
            expect(subject.spam?).to be_falsey
          end

          it 'logs an error' do
            expect(Gitlab::AppLogger).to receive(:error).with(/Error during Akismet.*flagging as not spam.*Lovely spam/)

            subject.spam?
          end
        end

        context 'ArgumentError is raised in dev' do
          let(:error) { ArgumentError }

          it 'raises original error' do
            expect { subject.spam? }.to raise_error(error)
          end
        end
      end
    end
  end

  describe '#submit_ham' do
    it_behaves_like 'no activity if Akismet is not enabled', :submit_ham
    it_behaves_like 'false if Akismet is not available', :submit_ham

    context 'if Akismet is available' do
      specify do
        expect(fake_akismet_client).to receive(:public_send).with(:ham, any_args)

        expect(subject.submit_ham).to be_truthy
      end
    end
  end

  describe '#submit_spam' do
    it_behaves_like 'no activity if Akismet is not enabled', :submit_spam
    it_behaves_like 'false if Akismet is not available', :submit_spam

    context 'if Akismet is available' do
      specify do
        expect(fake_akismet_client).to receive(:public_send).with(:spam, any_args)

        expect(subject.submit_spam).to be_truthy
      end
    end
  end
end

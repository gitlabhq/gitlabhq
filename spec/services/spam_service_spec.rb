# frozen_string_literal: true

require 'spec_helper'

describe SpamService do
  describe '#when_recaptcha_verified' do
    def check_spam(issue, request, recaptcha_verified)
      described_class.new(spammable: issue, request: request).when_recaptcha_verified(recaptcha_verified) do
        'yielded'
      end
    end

    it 'yields block when recaptcha was already verified' do
      issue = build_stubbed(:issue)

      expect(check_spam(issue, nil, true)).to eql('yielded')
    end

    context 'when recaptcha was not verified' do
      let(:project) { create(:project, :public) }
      let(:issue)   { create(:issue, project: project) }
      let(:request) { double(:request, env: {}) }

      context 'when spammable attributes have not changed' do
        before do
          issue.closed_at = Time.zone.now

          allow(AkismetService).to receive(:new).and_return(double(spam?: true))
        end

        it 'returns false' do
          expect(check_spam(issue, request, false)).to be_falsey
        end

        it 'does not create a spam log' do
          expect { check_spam(issue, request, false) }
            .not_to change { SpamLog.count }
        end
      end

      context 'when spammable attributes have changed' do
        before do
          issue.description = 'SPAM!'
        end

        context 'when indicated as spam by akismet' do
          shared_examples 'akismet spam' do
            it "doesn't check as spam when request is missing" do
              check_spam(issue, nil, false)

              expect(issue).not_to be_spam
            end

            it 'creates a spam log' do
              expect { check_spam(issue, request, false) }
                .to log_spam(title: issue.title, description: issue.description, noteable_type: 'Issue')
            end

            it 'does not yield to the block' do
              expect(check_spam(issue, request, false))
                .to eql(SpamLog.last)
            end
          end

          before do
            allow(AkismetService).to receive(:new).and_return(double(spam?: true))
          end

          context 'when allow_possible_spam feature flag is false' do
            before do
              stub_feature_flags(allow_possible_spam: false)
            end

            it_behaves_like 'akismet spam'

            it 'checks as spam' do
              check_spam(issue, request, false)

              expect(issue.spam).to be_truthy
            end
          end

          context 'when allow_possible_spam feature flag is true' do
            it_behaves_like 'akismet spam'

            it 'does not check as spam' do
              check_spam(issue, request, false)

              expect(issue.spam).to be_nil
            end
          end
        end

        context 'when not indicated as spam by akismet' do
          before do
            allow(AkismetService).to receive(:new).and_return(double(spam?: false))
          end

          it 'returns false' do
            expect(check_spam(issue, request, false)).to be_falsey
          end

          it 'does not create a spam log' do
            expect { check_spam(issue, request, false) }
              .not_to change { SpamLog.count }
          end
        end
      end
    end
  end
end

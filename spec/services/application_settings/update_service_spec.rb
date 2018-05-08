require 'spec_helper'

describe ApplicationSettings::UpdateService do
  let(:application_settings) { Gitlab::CurrentSettings.current_application_settings }
  let(:admin) { create(:user, :admin) }
  let(:params) { {} }

  subject { described_class.new(application_settings, admin, params) }

  before do
    # So the caching behaves like it would in production
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'updating terms' do
    context 'when the passed terms are blank' do
      let(:params) { { terms: ''  } }

      it 'does not create terms' do
        expect { subject.execute }.not_to change { ApplicationSetting::Term.count }
      end
    end

    context 'when passing terms' do
      let(:params) { { terms: 'Be nice!  '  } }

      it 'creates the terms' do
        expect { subject.execute }.to change { ApplicationSetting::Term.count }.by(1)
      end

      it 'does not create terms if they are the same as the existing ones' do
        create(:term, terms: 'Be nice!')

        expect { subject.execute }.not_to change { ApplicationSetting::Term.count }
      end

      it 'updates terms if they already existed' do
        create(:term, terms: 'Other terms')

        subject.execute

        expect(application_settings.terms).to eq('Be nice!')
      end

      it 'Only queries once when the terms are changed' do
        create(:term, terms: 'Other terms')
        expect(application_settings.terms).to eq('Other terms')

        subject.execute

        expect(application_settings.terms).to eq('Be nice!')
        expect { 2.times { application_settings.terms } }
          .not_to exceed_query_limit(0)
      end
    end
  end
end

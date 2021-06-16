# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserDetail do
  it { is_expected.to belong_to(:user) }

  describe 'validations' do
    describe '#job_title' do
      it { is_expected.not_to validate_presence_of(:job_title) }
      it { is_expected.to validate_length_of(:job_title).is_at_most(200) }
    end

    describe '#pronouns' do
      it { is_expected.not_to validate_presence_of(:pronouns) }
      it { is_expected.to validate_length_of(:pronouns).is_at_most(50) }
    end

    describe '#bio' do
      it { is_expected.to validate_length_of(:bio).is_at_most(255) }
    end
  end

  describe '#bio_html' do
    let(:user) { create(:user, bio: 'some **bio**') }

    subject { user.user_detail.bio_html }

    it 'falls back to #bio when the html representation is missing' do
      user.user_detail.update!(bio_html: nil)

      expect(subject).to eq(user.user_detail.bio)
    end

    it 'stores rendered html' do
      expect(subject).to include('some <strong>bio</strong>')
    end

    it 'does not try to set the value when the column is not there' do
      without_bio_html_column = UserDetail.column_names - ['bio_html']

      expect(described_class).to receive(:column_names).at_least(:once).and_return(without_bio_html_column)
      expect(user.user_detail).not_to receive(:bio_html=)

      subject
    end
  end
end

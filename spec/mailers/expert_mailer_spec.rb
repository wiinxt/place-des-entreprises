# frozen_string_literal: true

require 'rails_helper'
require 'mailers/shared_examples_for_an_email'

describe ExpertMailer do
  describe '#notify_company_needs' do
    subject(:mail) { described_class.notify_company_needs(expert, need).deliver_now }

    let(:expert) { create :expert }
    let(:user) { create :user }
    let(:diagnosis) { create :diagnosis_completed, advisor: user, visitee: create(:contact) }
    let(:need) { diagnosis.needs.first }

    describe 'email behavior' do
      it_behaves_like 'an email'

      it { expect(mail.header[:from].value).to eq ExpertMailer::SENDER }
    end

    describe 'password instructions reminder' do
      let(:expert) { create :expert, users: expert_members }

      # On ne renvoie plus les invitations automatiquement pour ne pas harceler les conseillers
      context 'any expert' do
        let(:expert_members) { [build(:user, invitation_accepted_at: nil)] }
        let(:expert_members2) { [build(:user, invitation_accepted_at: DateTime.now)] }
        let(:user1) { build :user, invitation_sent_at: nil, encrypted_password: '' }
        let(:user2) { build :user, invitation_sent_at: nil, encrypted_password: '', deleted_at: Time.zone.now }

        it { expect_any_instance_of(User).not_to receive(:send_reset_password_instructions) }
      end
    end
  end

  describe '#remind_involvement' do
    subject(:mail) do
      described_class.remind_involvement(expert).deliver_now
    end

    let(:expert) { create :expert }

    before do
      create :match, expert: expert, created_at: 5.days.ago
    end

    it_behaves_like 'an email'

    it { expect(mail.header[:from].value).to eq ExpertMailer::SENDER }
  end
end

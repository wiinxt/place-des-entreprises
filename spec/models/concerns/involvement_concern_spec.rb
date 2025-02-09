# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InvolvementConcern do
  let(:current_expert) { create :expert, users: [user] }
  let(:other_expert) { create :expert }
  let(:user) { create :user }
  let(:diagnosis) { create :diagnosis_completed }

  describe 'InvolvementConcern' do
    let!(:need_quo) do
      create(:need, matches: [create(:match, expert: current_expert, status: :quo)])
    end
    let!(:need_other_refused) do
      create(:need, matches: [
        create(:match, expert: current_expert, status: :quo),
        create(:match, expert: other_expert, status: :not_for_me)
      ])
    end
    let!(:need_other_taking_care) do
      create(:need, diagnosis: diagnosis, matches: [
        create(:match, expert: current_expert, status: :quo),
        create(:match, expert: other_expert, status: :taking_care)
      ])
    end
    let!(:need_other_done) do
      create(:need, diagnosis: diagnosis, matches: [
        create(:match, expert: current_expert, status: :quo),
        create(:match, expert: other_expert, status: :done)
      ])
    end
    let!(:need_taking_care) do
      create(:need, diagnosis: diagnosis, matches: [create(:match, expert: current_expert, status: :taking_care)])
    end
    let!(:need_quo_old) do
      create(:need, matches: [create(:match, expert: current_expert, status: :quo, created_at: 46.days.ago)])
    end
    let!(:need_other_done_old) do
      create(:need, matches: [
        create(:match, expert: current_expert, status: :quo, created_at: 46.days.ago),
        create(:match, expert: other_expert, status: :done, created_at: 46.days.ago)
      ])
    end
    let!(:need_other_refused_old) do
      create(:need, matches: [
        create(:match, expert: current_expert, status: :quo, created_at: 46.days.ago),
        create(:match, expert: other_expert, status: :not_for_me, created_at: 46.days.ago)
      ])
    end
    let!(:need_not_for_me) do
      create(:need, diagnosis: diagnosis, matches: [create(:match, expert: current_expert, status: :not_for_me)])
    end
    let!(:need_done) do
      create(:need, matches: [create(:match, expert: current_expert, status: :done)])
    end
    let!(:need_archived) do
      create(:need, matches: [create(:match, expert: current_expert, status: :quo)], archived_at: Time.zone.now)
    end

    describe 'needs_taking_care' do
      subject { user.needs_taking_care }

      it { is_expected.to contain_exactly(need_taking_care) }
    end

    describe 'needs_quo' do
      subject { user.needs_quo }

      it { is_expected.to contain_exactly(need_quo, need_other_taking_care, need_other_done, need_other_refused, need_quo_old, need_other_done_old, need_other_refused_old) }
    end

    describe 'needs_quo_active' do
      subject { user.needs_quo_active }

      it { is_expected.to contain_exactly(need_quo, need_other_taking_care, need_other_done, need_other_refused) }
    end

    describe 'needs_others_taking_care' do
      subject { user.needs_others_taking_care }

      it { is_expected.to contain_exactly(need_other_taking_care) }
    end

    describe 'needs_not_for_me' do
      subject { user.needs_not_for_me }

      it { is_expected.to contain_exactly(need_not_for_me) }
    end

    describe 'needs_done' do
      subject { user.needs_done }

      it { is_expected.to contain_exactly(need_done) }
    end

    describe 'needs_archived' do
      # besoin non pris en charge et avec un match de l’expert archivé
      let!(:need_quo_expert_match_archived) do
        matches = [create(:match, expert: current_expert, status: :quo, archived_at: Time.zone.now), create(:match, status: :quo)]
        create(:need, diagnosis: create(:diagnosis_completed), matches: matches)
      end
      # besoin non pris en charge et avec un match d’un autre expert archivé
      let!(:need_quo_another_expert_match_archived) do
        matches = [create(:match, expert: current_expert, status: :quo), create(:match, status: :quo, archived_at: Time.zone.now)]
        create(:need, diagnosis: create(:diagnosis_completed), matches: matches)
      end
      # besoin refusé par l’expert et non archivé
      let!(:need_refused_not_archived) do
        create(:need, diagnosis: create(:diagnosis_completed), matches: [create(:match, expert: current_expert, status: :quo)])
      end

      subject { user.needs_archived }

      it { is_expected.to contain_exactly(need_archived, need_quo_expert_match_archived) }
    end

    describe 'needs_expired' do
      subject { user.needs_expired }

      it { is_expected.to contain_exactly(need_quo_old, need_other_done_old, need_other_refused_old) }
    end
  end
end

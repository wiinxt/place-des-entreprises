module RemindersSpecHelper
  def create_experts_for_reminders
    # Expert avec plus de 2 besoins de plus de 15 jours en attente
    # et avec un stock de plus de 5 besoins non pris en charge
    let(:expert_with_many_old_quo_matches) { create :expert_with_users }
    let!(:quo_matches_1) { create_list :match, 4, status: :quo, expert: expert_with_many_old_quo_matches }
    let!(:many_old_quo_maches) { travel_to(16.days.ago) { create_list :match, 2, status: :quo, expert: expert_with_many_old_quo_matches } }

    # Expert avec plus de 2 besoins de plus de 45 jours en attente
    # et avec un stock de plus de 5 besoins non pris en charge
    let(:expert_with_many_abandoned_matches) { create :expert_with_users }
    let!(:abandoned_matches_1) { create_list :match, 4, status: :quo, expert: expert_with_many_abandoned_matches }
    let!(:many_old_abandoned_maches) { travel_to(46.days.ago) { create_list :match, 2, status: :quo, expert: expert_with_many_abandoned_matches } }

    # Expert moins de 2 besoins de plus de 15 jours en attente
    # et avec un stock de plus de 5 besoins non pris en charge
    let(:expert_with_many_quo_matches) { create :expert_with_users }
    let!(:quo_matches_2) { travel_to(16.days.ago) { create_list :match, 1, status: :quo, expert: expert_with_many_quo_matches } }
    let!(:many_quo_matches) { create_list :match, 5, status: :quo, expert: expert_with_many_quo_matches }

    # Expert avec plus de 2 besoins de plus de 15 jours en attente
    # et avec un stock > 2 < 5 de besoins non pris en charge
    let(:expert_with_medium_old_quo_matches) { create :expert_with_users }
    let!(:quo_matches_3) { create_list :match, 2, status: :quo, expert: expert_with_medium_old_quo_matches }
    let!(:medium_old_quo_matches) { travel_to(16.days.ago) { create_list :match, 2, status: :quo, expert: expert_with_medium_old_quo_matches } }

    # Expert avec plus de 2 besoins de plus de 45 jours en attente
    # et avec un stock > 2 < 5 de besoins non pris en charge
    let(:expert_with_medium_abandoned_matches) { create :expert_with_users }
    let!(:quo_matches_4) { create_list :match, 2, status: :quo, expert: expert_with_medium_abandoned_matches }
    let!(:medium_abandoned_matches) { travel_to(45.days.ago) { create_list :match, 2, status: :quo, expert: expert_with_medium_abandoned_matches } }

    # Expert moins de 2 besoins de plus de 15 jours en attente
    # et avec un stock > 2 < 5 de besoins non pris en charge
    let(:expert_with_medium_quo_matches) { create :expert_with_users }
    let!(:medium_quo_matches) { create_list :match, 4, status: :quo, expert: expert_with_medium_quo_matches }
    let!(:medium_old_quo_matches_2) { travel_to(16.days.ago) { create :match, status: :quo, expert: expert_with_medium_quo_matches } }

    # Expert avec 1 besoin de plus de 15 jours avec plus de 3 mois depuis le dernier besoin cloturé
    let(:expert_with_one_old_quo_match) { create :expert_with_users }
    let!(:old_quo_matches) { travel_to(16.days.ago) { create :match, status: :quo, expert: expert_with_one_old_quo_match } }
    let!(:old_done_matches_1) { travel_to(4.months.ago) { create :match, status: :done, expert: expert_with_one_old_quo_match } }

    # Expert avec 1 besoin de moins de 15 jours avec moins de 3 mois depuis le dernier besoin cloturé
    let(:expert_with_one_quo_match) { create :expert_with_users }
    let!(:old_quo_matches_1) { create :match, status: :quo, expert: expert_with_one_quo_match }
    let!(:old_done_matches_4) { travel_to(2.months.ago) { create :match, status: :done, expert: expert_with_one_quo_match } }

    # Expert avec 1 besoin de plus de 45 jours avec plus de 3 mois depuis le dernier besoin cloturé
    let(:expert_with_one_abandoned_match) { create :expert_with_users }
    let!(:old_quo_match) { travel_to(45.days.ago) { create :match, status: :quo, expert: expert_with_one_abandoned_match } }
    let!(:old_done_matches_2) { travel_to(4.months.ago) { create :match, status: :done, expert: expert_with_one_abandoned_match } }

    # Expert avec 1 besoin de moins de 15 jours avec plus de 3 mois depuis le dernier besoin cloturé
    let(:expert_with_one_quo_match_1) { create :expert_with_users }
    let!(:quo_match) { create :match, status: :quo, expert: expert_with_one_quo_match_1 }
    let!(:old_done_matches_3) { travel_to(4.months.ago) { create :match, status: :done, expert: expert_with_one_quo_match_1 } }
  end
end

module Stats::Matches
  # Taux de mises en relation clôturées faute d’avoir pu joindre l’entreprise sur la totalité des mises en relation transmises
  class DoneNotReachableRateStats
    include ::Stats::BaseStats

    def main_query
      Match.joins(:need).where.not(need: { status: :diagnosis_not_complete })
    end

    def filtered(query)
      if territory.present?
        query.merge! query.in_region(territory)
      end
      if institution.present?
        query.merge! query.joins(expert: :institution).where(experts: { institutions: institution })
      end
      query
    end

    def build_series
      query = main_query
      query = filtered(query)

      @not_reachable_status = []
      @other_status = []

      search_range_by_month.each do |range|
        month_query = query.created_between(range.first, range.last)
        @not_reachable_status.push(month_query.status_done_not_reachable.count)
        @other_status.push(month_query.not_status_done_not_reachable.count)
      end

      as_series(@not_reachable_status, @other_status)
    end

    def count
      build_series
      percentage_two_numbers(@not_reachable_status, @other_status)
    end

    private

    def as_series(not_reachable_status, other_status)
      [
        {
          name: I18n.t('stats.other_status'),
          data: other_status
        },
        {
          name: I18n.t('stats.not_reachable_status'),
          data: not_reachable_status
        }
      ]
    end
  end
end

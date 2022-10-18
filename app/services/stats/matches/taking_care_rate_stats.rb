module Stats::Matches
  # Taux de mises en relation en cours de prises en charge sur l’ensemble des mises en relation transmises
  class TakingCareRateStats
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

      @tacking_care_status = []
      @other_status = []

      search_range_by_month.each do |range|
        month_query = query.created_between(range.first, range.last)
        @tacking_care_status.push(month_query.status_taking_care.count)
        @other_status.push(month_query.not_status_taking_care.count)
      end

      as_series(@tacking_care_status, @other_status)
    end

    def count
      build_series
      percentage_two_numbers(@tacking_care_status, @other_status)
    end

    private

    def as_series(tacking_care_status, other_status)
      [
        {
          name: I18n.t('stats.other_status'),
          data: other_status
        },
        {
          name: I18n.t('stats.tacking_care_status'),
          data: tacking_care_status
        }
      ]
    end
  end
end

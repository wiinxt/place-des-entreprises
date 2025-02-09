module Stats::Matches
  # Taux de mises en relation refusées sur la totalité des mises en relation transmises
  class NotForMeRateStats
    include ::Stats::BaseStats
    include ::Stats::FiltersStats

    def main_query
      Match.sent.where(created_at: @start_date..@end_date)
    end

    def filtered(query)
      filtered_matches(query)
    end

    def build_series
      query = main_query
      query = filtered(query)

      @not_for_me_status = []
      @other_status = []

      search_range_by_month.each do |range|
        month_query = query.created_between(range.first, range.last)
        @not_for_me_status.push(month_query.status_not_for_me.count)
        @other_status.push(month_query.not_status_not_for_me.count)
      end

      as_series(@not_for_me_status, @other_status)
    end

    def count
      build_series
      percentage_two_numbers(@not_for_me_status, @other_status)
    end

    def subtitle
      I18n.t('stats.series.not_for_me_rate_stats.subtitle')
    end

    def colors
      matches_colors
    end

    private

    def as_series(not_for_me_status, other_status)
      [
        {
          name: I18n.t('stats.other_status'),
          data: other_status
        },
        {
          name: I18n.t('stats.not_for_me_status'),
          data: not_for_me_status
        }
      ]
    end
  end
end

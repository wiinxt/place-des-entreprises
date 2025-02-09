module Stats::Public
  class ExchangeWithExpertStats
    include ::Stats::BaseStats
    include ::Stats::FiltersStats

    def main_query
      # This stat is available since 2020-09-01
      Need.joins(:diagnosis)
        .merge(Diagnosis.from_solicitation.completed)
        .where(created_at: Time.zone.local(2020, 9, 1)..)
        .where(created_at: @start_date..@end_date)
    end

    def build_series
      query = filtered_main_query

      @needs_with_exchange = []
      @needs_without_exchange = []

      search_range_by_month.each do |range|
        month_query = query.created_between(range.first, range.last)
        @needs_with_exchange.push(month_query.with_exchange.count)
        @needs_without_exchange.push(month_query.without_exchange.count)
      end

      as_series(@needs_with_exchange, @needs_without_exchange)
    end

    def subtitle
      nil
    end

    def count
      build_series
      percentage_two_numbers(@needs_with_exchange, @needs_without_exchange)
    end

    def filtered_main_query
      filtered_needs(main_query)
    end

    def secondary_count
      filtered_main_query.with_exchange.size
    end

    # def format
    #   '{series.name} : <b>{point.percentage:.0f}%</b> (Total : {point.y})'
    # end

    private

    def as_series(needs_with_exchange, needs_without_exchange)
      [
        {
          name: I18n.t('stats.series.exchange_with_expert.without_exchange'),
          data: needs_without_exchange
        },
        {
          name: I18n.t('stats.series.exchange_with_expert.with_exchange'),
          data: needs_with_exchange
        }
      ]
    end
  end
end

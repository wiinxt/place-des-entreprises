class QuarterlyReportService
  class << self
    def generate_reports(antennes = Antenne.all)
      antennes.each do |antenne|
        quarters = last_quarters(antenne)
        next if quarters.nil?
        quarters.each do |quarter|
          generate_matches_files(antenne, quarter)
          generate_stats_files(antenne, quarter)
        end
        destroy_old_report_files(antenne, quarters)
      end
    end

    def send_emails
      User.managers.each do |user|
        next unless user.managed_antennes.map { |antenne| antenne.quarterly_reports.find_by(start_date: 3.months.ago.beginning_of_month) }.any?
        UserMailer.quarterly_report(user).deliver_later
      end
    end

    private

    def generate_matches_files(antenne, quarter)
      return if antenne.matches_reports.find_by(start_date: quarter.first).present?
      needs = antenne.perimeter_received_needs.created_between(quarter.first, quarter.last)
      return if needs.blank?

      matches = Match.joins(:need).where(need: needs)
      return if matches.blank?

      # la tâche peut être longue, on la met dans une transaction pour garantir un état stable (pas de Matchreport sans fichier, par exemple)
      ActiveRecord::Base.transaction do
        result = matches.export_xlsx
        filename = I18n.t('quarterly_report_service.matches_file_name', number: TimeDurationService.find_quarter(quarter.first.month), year: quarter.first.year, antenne: antenne.name.parameterize)
        report = antenne.matches_reports.create!(start_date: quarter.first, end_date: quarter.last)
        report.file.attach(io: result.xlsx.to_stream(true),
                           key: "quarterly_report_matches/#{antenne.name.parameterize}/#{filename}",
                           filename: filename,
                           content_type: 'application/xlsx')
      end
    end

    def generate_stats_files(antenne, quarter)
      return if antenne.stats_reports.find_by(start_date: quarter.first).present?

      ActiveRecord::Base.transaction do
        exporter = XlsxExport::AntenneStatsExporter.new({
          start_date: quarter.first,
              end_date: quarter.last,
              antenne: antenne
        })
        result = exporter.export

        filename = I18n.t('quarterly_report_service.stats_file_name', number: TimeDurationService.find_quarter(quarter.first.month), year: quarter.first.year, antenne: antenne.name.parameterize)
        report = antenne.stats_reports.create!(start_date: quarter.first, end_date: quarter.last)
        report.file.attach(io: result.xlsx.to_stream(true),
                           key: "quarterly_report_stats/#{antenne.name.parameterize}/#{filename}",
                           filename: filename,
                           content_type: 'application/xlsx')
      end
    end

    def destroy_old_report_files(antenne, quarters)
      antenne.quarterly_reports.where.not(start_date: quarters.flatten).destroy_all
    end

    def last_quarters(antenne)
      needs = antenne.perimeter_received_needs
      return if needs.blank?
      first_need_date = needs.minimum(:created_at).to_date
      quarters = TimeDurationService.past_year_quarters
      quarters.reject! { |range| first_need_date > range.last }
      quarters
    end
  end
end

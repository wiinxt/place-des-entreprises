# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  SENDER = "#{I18n.t('app_name')} Admin <#{SENDER_EMAIL}>"
  default from: SENDER, template_path: 'mailers/admin_mailer'

  helper :solicitation

  def weekly_statistics(public_stats_counts, reminders_counts)
    @public_stats_counts = public_stats_counts
    # TODO: Use Team Stats here as well once #1468 is merged
    @reminders_counts = reminders_counts

    mail(to: default_recipients, subject: t('mailers.admin_mailer.weekly_statistics.subject'))
  end

  def failed_jobs(jobs)
    @jobs = jobs

    mail(to: ENV['TECH_EMAIL'], subject: t('mailers.admin_mailer.failed_jobs.subject', count: @jobs.size))
  end

  def solicitation(solicitation)
    @solicitation = solicitation
    mail(to: default_recipients, subject: t('mailers.admin_mailer.solicitation.subject'))
  end

  def send_csv(model, ransack_params, file, user)
    @model_name = model.constantize.model_name.human.pluralize
    @ransack_params = ransack_params
    file_name = file.path.split('/').last
    attachments[file_name] = File.read(file.path)
    mail(to: user.email, subject: t('mailers.admin_mailer.csv_export', model: @model_name))
  end

  private

  def default_recipients
    ENV['APPLICATION_EMAIL']
  end
end

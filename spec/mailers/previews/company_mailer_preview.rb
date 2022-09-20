class CompanyMailerPreview < ActionMailer::Preview
  def confirmation_solicitation_from_pde
    CompanyMailer.confirmation_solicitation(Solicitation.where(institution: nil).sample)
  end

  def confirmation_solicitation_from_iframe
    CompanyMailer.confirmation_solicitation(Solicitation.where.not(institution: nil).sample)
  end

  def taking_care_solicitation
    CompanyMailer.notify_taking_care(Diagnosis.completed.from_solicitation.sample.matches.sample)
  end

  def not_reachable
    CompanyMailer.notify_not_reachable(Diagnosis.completed.from_solicitation.sample.matches.sample)
  end

  def satisfaction
    CompanyMailer.satisfaction(Need.where(status: :done).sample)
  end

  def retention
    CompanyMailer.retention(Need.where(status: :done).sample)
  end

  def abandoned_need
    CompanyMailer.abandoned_need(Diagnosis.completed.from_solicitation.sample.needs.sample)
  end

  def solicitation_relaunch
    CompanyMailer.solicitation_relaunch(Solicitation.status_step_company.where.not(uuid: nil).sample)
  end
end

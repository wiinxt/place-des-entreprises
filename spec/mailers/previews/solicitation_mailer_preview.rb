class SolicitationMailerPreview < ActionMailer::Preview
  def bad_quality
    SolicitationMailer.bad_quality(random_solicitation)
  end

  def particular_retirement
    SolicitationMailer.particular_retirement(random_solicitation)
  end

  def creation
    SolicitationMailer.creation(random_solicitation)
  end

  def siret
    SolicitationMailer.siret(random_solicitation)
  end

  def moderation
    SolicitationMailer.moderation(random_solicitation)
  end

  def independent_tva
    SolicitationMailer.independent_tva(random_solicitation)
  end

  def intermediary
    SolicitationMailer.intermediary(random_solicitation)
  end

  def recruitment_foreign_worker
    SolicitationMailer.recruitment_foreign_worker(random_solicitation)
  end

  private

  def random_solicitation
    Solicitation.joins(:landing_subject).sample
  end
end

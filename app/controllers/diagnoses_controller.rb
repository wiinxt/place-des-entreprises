# frozen_string_literal: true

class DiagnosesController < ApplicationController
  before_action :retrieve_diagnosis, only: %i[show archive unarchive]
  before_action :maybe_review_expert_subjects

  def index
    authorize Diagnosis
    @diagnoses = sent_diagnoses(current_user, archived: false)
  end

  def new
    @params = {}
    @solicitation = Solicitation.find_by(id: params[:solicitation])
  end

  def index_antenne
    @diagnoses = sent_diagnoses(current_user.antenne, archived: false)
  end

  def archives
    @diagnoses = sent_diagnoses(current_user, archived: true)
  end

  def archives_antenne
    @diagnoses = sent_diagnoses(current_user.antenne, archived: true)
  end

  def create_diagnosis_without_siret
    insee_code = params[:insee_code]
    facility = Facility.new(company: Company.new(name: params[:name]))
    city_params = ApiAdresse::Query.city_with_code(insee_code)
    facility.readable_locality = "#{city_params['codesPostaux']&.first} #{city_params['nom']}"
    facility.commune = Commune.find_or_initialize_by(insee_code: insee_code)

    diagnosis = Diagnosis.new(advisor: current_user, facility: facility, step: :needs)
    if params[:solicitation].present?
      solicitation = Solicitation.find_by(id: params[:solicitation])
      diagnosis.solicitation = solicitation
    end

    if diagnosis.save
      redirect_to needs_diagnosis_path(diagnosis)
    else
      render body: nil, status: :bad_request
    end
  end

  def show
    authorize @diagnosis
    if @diagnosis.step_completed?
      redirect_to need_path(@diagnosis)
    else
      redirect_to controller: 'diagnoses/steps', action: @diagnosis.step, id: @diagnosis
    end
  end

  def archive
    authorize @diagnosis, :update?
    @diagnosis.archive!
    redirect_to diagnoses_path
  end

  def unarchive
    authorize @diagnosis, :update?
    @diagnosis.unarchive!
    redirect_to diagnoses_path
  end

  private

  def sent_diagnoses(model, archived:)
    model.sent_diagnoses.archived(archived).order(created_at: :desc)
      .distinct
      .left_outer_joins(:matches,
                        needs: :matches)
      .includes(:matches,
                :visitee, facility: :company,
        needs: :matches)
  end

  def retrieve_diagnosis
    @diagnosis = Diagnosis.find(params.require(:id))
  end
end

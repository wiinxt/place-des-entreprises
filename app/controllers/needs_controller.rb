# frozen_string_literal: true

class NeedsController < ApplicationController
  before_action :maybe_review_expert_subjects
  before_action :retrieve_need, only: %i[archive unarchive]

  layout 'side_menu', except: :show

  ## Collection actions
  # (aka “index pages”)
  # TODO: The collections rely on InvolvementConcern being used on User and Antenne.
  # We could simply have one route and get the name of the collection as a parameter, like this;
  # /besoins(/antenne)/:collection_name
  # However, Needs#show is already used to display the _completed diagnoses_, like this:
  # /besoins/:diagnosis_id
  # This is… sub-optimal. We might want to use Diagnoses#show for this; it is already used for in-progress diagnoses.
  # Note: We would still need to handle redirections, because the diagnoses paths are the ones sent by email to experts.
  # TODO: Another issue is that the collections in /besoins/ are actually collections of diagnoses.
  # All of this is #1278.
  def index
    redirect_to action: :quo
  end

  def quo
    retrieve_needs(current_user, :quo)
  end

  def taking_care
    retrieve_needs(current_user, :taking_care)
  end

  def done
    retrieve_needs(current_user, :done)
  end

  def not_for_me
    retrieve_needs(current_user, :not_for_me)
  end

  def archived
    retrieve_needs(current_user, :archived)
  end

  def antenne_quo
    retrieve_needs(current_user.antenne, :quo)
  end

  def antenne_taking_care
    retrieve_needs(current_user.antenne, :taking_care)
  end

  def antenne_done
    retrieve_needs(current_user.antenne, :done)
  end

  def antenne_not_for_me
    retrieve_needs(current_user.antenne, :not_for_me)
  end

  def antenne_archived
    retrieve_needs(current_user.antenne, :archived)
  end

  private

  def collection_names
    %i[quo taking_care done not_for_me archived]
  end

  # Common render method for collection actions
  def retrieve_needs(recipient, collection_name)
    @user = current_user
    @antenne = current_user.antenne
    @recipient = recipient

    @collections_counts = Rails.cache.fetch(recipient.received_needs) do
      collection_names.index_with { |name| recipient.send("needs_#{name}").size }
    end
    @collection_name = collection_name

    @needs = recipient
      .send("needs_#{collection_name}") # See InvolvementConcern
      .includes(:company, :advisor, :subject)
      .page params[:page]
    render :index
  end

  ## Instance actions
  #
  public

  def show
    @diagnosis = retrieve_diagnosis
    authorize @diagnosis
    unless @diagnosis.step_completed?
      # let diagnoses_controller (and steps_controller) handle incomplete diagnoses
      redirect_to @diagnosis and return
    end

    @highlighted_experts = highlighted_experts
  end

  def additional_experts
    @need = Need.find(params.require(:need))
    @query = params.require('query')&.strip

    @experts = Expert.omnisearch(@query)
      .with_subjects
      .where.not(id: @need.experts)
      .limit(15)
      .includes(:antenne, experts_subjects: :institution_subject)
  end

  def add_match
    @diagnosis = retrieve_diagnosis

    @need = Need.find(params.require(:need))
    expert_subject = ExpertSubject.find(params.require(:expert_subject))
    expert = expert_subject.expert
    @match = Match.create(need: @need, expert: expert, subject: @need.subject)
    if @match.valid?
      ExpertMailer.notify_company_needs(expert, @diagnosis).deliver_later
      expert.first_notification_help_email
    else
      flash.alert = @match.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_path)
    end
  end

  def archive
    authorize @need, :archive?
    @need.archive!
    flash[:notice] = t('.subjet_achived')
    redirect_back fallback_location: need_path(@need.diagnosis),
                  notice: t('needs.archive.archive_done', company: @need.company.name)
  end

  def unarchive
    authorize @need, :archive?
    @need.update(archived_at: nil)
    flash[:notice] = t('.subject_unarchived')
    redirect_to need_path(@need.diagnosis)
  end

  private

  def highlighted_experts
    begin
      [Expert.find(params.require(:highlighted_expert))]
    rescue
      []
    end
  end

  def retrieve_diagnosis
    Diagnosis.find(params.require(:id))
  end

  def retrieve_need
    @need = Need.find(params.require(:id))
  end
end

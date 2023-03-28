module Reminders
  class ExpertsController < BaseController
    include Inbox
    helper_method :inbox_collections_counts
    before_action :persist_search_params, :setup_territory_filters, :collections_counts, only: %i[index show many_pending_needs medium_pending_needs one_pending_need inputs outputs]
    before_action :retrieve_expert, except: %i[index many_pending_needs medium_pending_needs one_pending_need inputs outputs]

    def index
      redirect_to action: :many_pending_needs
    end

    def many_pending_needs
      render_collection(:many_pending_needs)
    end

    def medium_pending_needs
      render_collection(:medium_pending_needs)
    end

    def one_pending_need
      render_collection(:one_pending_need)
    end

    def inputs
      render_collection(:inputs)
    end

    def outputs
      render_collection(:outputs)
    end

    def quo_active
      retrieve_needs(@expert, :quo_active, view: :quo)
    end

    def taking_care
      retrieve_needs(@expert, :taking_care, view: :quo)
    end

    def done
      retrieve_needs(@expert, :done, view: :quo)
    end

    def not_for_me
      retrieve_needs(@expert, :not_for_me, view: :quo)
    end

    def quo_abandoned
      retrieve_needs(@expert, :quo_abandoned, view: :quo)
    end

    def show
      @action = :many_pending_needs
    end

    def send_reminder_email
      @expert = Expert.find(params.permit(:id)[:id])
      ExpertMailer.positioning_rate_reminders(@expert, current_user).deliver_later
      @feedback = Feedback.create(user: current_user, category: :expert_reminder, description: t('.email_send'), feedbackable_type: 'Expert', feedbackable_id: @expert.id)
      respond_to do |format|
        format.js
        format.html { redirect_to many_pending_needs_reminders_experts_path, notice: t('mailers.email_sent') }
      end
    end

    private

    def setup_territory_filters
      @possible_territories_options = Territory.deployed_regions.map do |territory|
        [territory.name, territory.id]
      end
      @possible_territories_options.push(
        [ t('helpers.expert.national_perimeter.label'), t('helpers.expert.national_perimeter.value') ],
      )
    end

    def safe_params
      params.permit(:id)
    end

    def retrieve_expert
      @expert = Expert.find(safe_params[:id])
    end

    def render_collection(action)
      @active_experts = territory_experts
        .includes(:reminder_feedbacks, :users, :received_needs)
        .send(action)
        .most_needs_quo_first
        .page params[:page]

      @action = action
      render :index
    end

    def territory_experts
      Expert.apply_filters(relance_expert_params)
    end

    def relance_expert_params
      session[:relance_expert_params]&.with_indifferent_access || {}
    end
    helper_method :relance_expert_params

    def persist_search_params
      session[:relance_expert_params] ||= {}
      search_params = params.slice(:by_region).permit!
      if params[:reset_query].present?
        session[:relance_expert_params] = {}
      else
        session[:relance_expert_params] = session[:relance_expert_params].merge(search_params)
      end
    end
  end
end

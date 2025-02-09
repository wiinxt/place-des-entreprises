module Reminders
  class ExpertsController < BaseController
    include Inbox
    helper_method :inbox_collections_counts
    before_action :persist_filter_params, :setup_territory_filters, :collections_counts, only: %i[index show many_pending_needs medium_pending_needs one_pending_need inputs outputs]
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

    def expired
      retrieve_needs(@expert, :expired, view: :quo)
    end

    def show
      @action = :many_pending_needs
    end

    def send_reminder_email
      expert = Expert.find(params.permit(:id)[:id])
      ExpertMailer.positioning_rate_reminders(expert, current_user).deliver_later
      Feedback.create(user: current_user, category: :expert_reminder, description: t('.email_send'),
                      feedbackable_type: 'Expert', feedbackable_id: expert.id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("display-feedbacks-#{expert.id}",
                                                   partial: "reminders/experts/expert_feedbacks",
                                                   locals: { expert: expert })
          format.html { redirect_back fallback_location: many_pending_need_reminders_experts_path }
        end
      end
    end

    def send_re_engagement_email
      expert = Expert.find(params.permit(:id)[:id])
      need = expert.received_quo_matches.first.need
      ExpertMailer.re_engagement(expert, current_user, need).deliver_later
      Feedback.create(user: current_user, category: :expert_reminder, description: t('.re_engagement_email_send'),
                      feedbackable_type: 'Expert', feedbackable_id: expert.id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("display-feedbacks-#{expert.id}",
                                                   partial: "reminders/experts/expert_feedbacks",
                                                   locals: { expert: expert })
        end
        format.html { redirect_to one_pending_need_reminders_experts_path }
      end
    end

    private

    def retrieve_expert
      @expert = Expert.find(params.permit(:id)[:id])
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
  end
end

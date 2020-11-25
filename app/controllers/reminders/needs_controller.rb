module Reminders
  class NeedsController < RemindersController
    before_action :find_territories

    def index
      retrieve_needs :reminder_quo_not_taken
    end

    def to_recall
      retrieve_needs :reminder_to_recall
      render :index
    end

    def institutions
      retrieve_needs :reminder_institutions
      render :index
    end

    def abandoned
      retrieve_needs :abandoned_without_taking_care
      render :index
    end

    def rejected
      retrieve_needs :rejected
      render :index
    end

    private

    def find_territories
      @territories = Territory.regions.order(:name)
      @territory = retrieve_territory
    end

    def retrieve_needs(scope)
      @needs = if @territory.present?
        Need.diagnosis_completed.send(scope).joins(:diagnosis).where(diagnoses: { facility: @territory&.facilities }).includes(:subject).page(params[:page])
      else
        Need.diagnosis_completed.send(scope).includes(:subject).page(params[:page])
      end
      @status = t("reminders.needs.header.#{scope}").downcase
    end
  end
end

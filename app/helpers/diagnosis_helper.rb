# frozen_string_literal: true

module DiagnosisHelper
  def html_classes_for_step(displayed_step, current_page_step, diagnosis_step)
    is_completed = displayed_step < diagnosis_step
    is_active = displayed_step == current_page_step

    if is_completed && is_active
      'completed active'
    elsif is_active
      'active'
    elsif is_completed
      'completed'
    end
  end

  def assistances_experts_localized(diagnosed_need:, assistances_experts_of_location:)
    diagnosed_need.question.assistances.map(&:assistances_experts).flatten & assistances_experts_of_location
  end
end

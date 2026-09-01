# frozen_string_literal: true

class GanttController < InertiaController
  before_action :require_current_organization

  def index
    render inertia: "gantt/index"
  end
end

# frozen_string_literal: true

module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :organization
    default_scope { where(organization_id: Current.organization&.id) }

    before_validation :assign_current_organization, on: :create
    validates :organization_id, presence: true
  end

  private

  def assign_current_organization
    self.organization_id ||= Current.organization&.id
  end
end

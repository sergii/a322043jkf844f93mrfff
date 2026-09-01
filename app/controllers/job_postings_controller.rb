# frozen_string_literal: true

class JobPostingsController < InertiaController
  before_action :require_current_organization

  def create
    job = Job.find_by_typed_id!(params[:job_id])
    attributes = posting_params
    posting = job.job_postings.find_or_initialize_by(public_url: attributes.fetch(:public_url))
    posting.assign_attributes(attributes)
    authorize! posting, to: posting.persisted? ? :update? : :create?

    if posting.save
      redirect_to job_path(job), notice: "Job posting #{posting.previously_new_record? ? "saved" : "updated"}"
    else
      redirect_to job_path(job), inertia: { errors: posting.errors }
    end
  end

  def update
    posting = JobPosting.find_by_typed_id!(params[:id])
    authorize! posting

    if posting.update(posting_params)
      redirect_to job_path(posting.job), notice: "Job posting updated"
    else
      redirect_to job_path(posting.job), inertia: { errors: posting.errors }
    end
  end

  private

  def posting_params
    params.permit(:channel, :status, :title, :public_url, :content_snapshot, :published_at, :closed_at)
  end
end

# frozen_string_literal: true
require 'sinatra'

# /api/v1/projects routes only
class ShareConfigurationsAPI < Sinatra::Base
  get '/api/v1/projects/:proj_id' do
    content_type 'application/json'

    begin
      account = authenticated_account(env)
      project = Project[params[:proj_id]]

      check_policy = ProjectPolicy.new(account, project)
      raise unless check_policy.can_view_project?
      project.full_details
             .merge(policies: check_policy.summary)
             .to_json
    rescue => e
      error_msg = "PROJECT NOT FOUND: \"#{params[:proj_id]}\""
      logger.error e.inspect
      halt 401, error_msg
    end
  end

  # Make a new project
  post '/api/v1/projects/?' do
    content_type 'application/json'

    begin
      account = authenticated_account(env)
      raise unless account

      new_project_data = JSON.parse(request.body.read)
      saved_project = CreateProjectForOwner.call(
        owner_id: account.id,
        name: new_project_data['name'],
        repo_url: new_project_data['repo_url']
      )
    rescue => e
      logger.info "FAILED to create new project: #{e.inspect}"
      halt 400
    end

    status 201
    saved_project.to_json
  end
end

#spec/support/request_spec_helper
module RequestSpecHelper
  # Parse JSON to ruby hash
  def json
    JSON.parse(response.body)
  end
end

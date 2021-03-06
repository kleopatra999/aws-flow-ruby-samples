# Copyright 2014-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require_relative '../../../utils'
require_relative 'retry_activities'

# CustomJitterRetryWorkflow class defines a workflow for the retry_activity
# recipes. This recipe shows how to set up a custom jitter retry policy for
# activity executions.
class CustomJitterRetryWorkflow
  extend AWS::Flow::Workflows

  workflow :process do
    {
      version: "1.0",
      task_list: "workflow_tasklist",
      execution_start_to_close_timeout: 120,
    }
  end

  # Create an activity client using the activity_client method to schedule
  # activities. Set the activity runtime options by passing in activity options
  # as a has to the activity client. Here we set the should_jitter option to
  # true and pass in a lambda that defines our custom retry policy. Note that
  # jitter is switched on by default in the flow framework.
  activity_client(:client) do
    {
      from_class: "RetryActivities",
      exponential_retry: {
        should_jitter: true,
        jitter_function: lambda do |seed, max_value|
          Random.new(seed.to_i).rand(max_value)
        end,
        maximum_attempts: 5,
        exceptions_to_retry: [StandardError],
      }
    }
  end

  def process
    client.unreliable_activity_with_retry_options
  end
end

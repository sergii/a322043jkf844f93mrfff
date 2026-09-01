# frozen_string_literal: true

require Rails.root.join("lib/enforceable/hire_do_action_policy_binding")
require "enforceable/runner"

EnforceableActionPolicyBinding = Enforceable::HireDoActionPolicyBinding
EnforceableActor = Enforceable::HireDoActionPolicyBinding::Actor

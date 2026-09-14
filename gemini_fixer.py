from litellm.integrations.custom_logger import CustomLogger

class GeminiFixer(CustomLogger):
    def _apply_fix(self, data):
        try:
            messages = data.get("messages", [])
            for msg in messages:
                role = msg.get("role")
                # Intercept Assistant Tool Calls
                if role == "assistant" and "tool_calls" in msg:
                    for tc in msg["tool_calls"]:
                        tc_id = tc.get("id", "")
                        if tc_id and "__thought__" not in tc_id:
                            tc["id"] = f"{tc_id}__thought__skip_thought_signature_validator"
                # Intercept Tool Execution Responses
                elif role == "tool" and "tool_call_id" in msg:
                    tc_id = msg.get("tool_call_id", "")
                    if tc_id and "__thought__" not in tc_id:
                        msg["tool_call_id"] = f"{tc_id}__thought__skip_thought_signature_validator"
        except Exception as e:
            print(f"[GeminiFixer] Error: {e}")
        return data

    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type, **kwargs):
        self._apply_fix(data)
        return data

    def pre_call_hook(self, user_api_key_dict, cache, data, call_type, **kwargs):
        self._apply_fix(data)
        return data

proxy_handler_instance = GeminiFixer()

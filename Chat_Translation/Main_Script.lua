--====================  API 密钥  ====================
_G.DeepSeek_APIKey  = "你的DeepSeek密钥"
_G.OpenAI_APIKey    = "你的OpenAI密钥"
_G.Claude_APIKey    = "你的Claude密钥"
_G.Gemini_APIKey    = "你的Gemini密钥"

--====================  基础配置  ====================
_G.TargetLang = "zh-cn"        -- 目标语言（默认 zh-cn）
_G.CurrentAPI  = "deepseek"   -- 当前使用的 API（默认 deepseek）

--====================  模型配置  ====================
_G.DeepSeek_Model = "deepseek-chat"
_G.OpenAI_Model   = "gpt-4"
_G.Claude_Model   = "claude-3-sonnet-20240229"
_G.Gemini_Model   = "gemini-pro-vision"

--====================  加载脚本  ====================
loadstring(game:HttpGet("https://raw.githubusercontent.com/tongblox/scripts/refs/heads/main/Chat_Translation/Chat_Translation.lua"))()
